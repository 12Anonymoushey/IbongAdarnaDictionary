import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import 'pilak_product.dart';
import '../../services/app_feedback.dart';

int calculateQuizPilak(int score, int attempts) {
  if (score < 0 || attempts < 0) {
    throw ArgumentError('Score and attempts must not be negative.');
  }
  final multiplier = math.max(0.0, 1 - (0.33 * attempts));
  return (score * multiplier).floor();
}

int calculateAdarnaQuizPilak(
  int score,
  int attempts, {
  required bool adarnaModeEnabled,
}) {
  return calculateQuizPilak(score, attempts) * (adarnaModeEnabled ? 2 : 1);
}

int calculateReadingPilak(int minutes) {
  if (minutes < 0) {
    throw ArgumentError.value(minutes, 'minutes', 'Must not be negative.');
  }
  return (15 * (math.log(minutes + 1) / math.ln2)).floor();
}

int calculateDailyStreakPilak(int days) {
  if (days < 0) {
    throw ArgumentError.value(days, 'days', 'Must not be negative.');
  }
  return 10 + (5 * math.min(days, 14));
}

bool shouldEarnAdarnaHeart({
  required int score,
  required int maxScore,
  required bool firstTry,
}) {
  if (score < 0 || maxScore < 0 || score > maxScore) {
    throw ArgumentError('Quiz score must be between zero and max score.');
  }
  return firstTry && maxScore > 0 && score * 4 >= maxScore * 3;
}

class PilakService extends ChangeNotifier {
  PilakService._();

  static final PilakService instance = PilakService._();
  static const _storageKey = 'pilak_economy_state';
  static const _hours24 = Duration(hours: 24);

  SharedPreferences? _preferences;
  Future<void>? _initialization;
  Future<void> _transactionTail = Future<void>.value();
  int _balance = 0;
  final Set<String> _purchasedItemIds = {};
  String? _activeThemeId;
  int _streakDays = 0;
  DateTime? _lastLoginAt;
  DateTime? _streakFreezeUntil;
  int _quizDecayResetCredits = 0;
  String? _readingDate;
  int _readingMinutesToday = 0;
  bool _adarnaModeEnabled = false;
  int _adarnaHearts = 3;
  final List<Map<String, Object?>> _transactions = [];
  final Map<String, int> _readingHistory = {};
  final List<String> _loginHistory = [];
  int _longestStreak = 0;
  bool _isInitialized = false;

  int get balance => _balance;
  Set<String> get purchasedItemIds => Set.unmodifiable(_purchasedItemIds);
  String? get activeThemeId => _activeThemeId;
  int get streakDays => _streakDays;
  bool get isInitialized => _isInitialized;
  bool get hasActiveStreakFreeze =>
      _streakFreezeUntil?.isAfter(DateTime.now()) ?? false;
  int get quizDecayResetCredits => _quizDecayResetCredits;
  bool get adarnaModeEnabled => _adarnaModeEnabled;
  int get adarnaHearts => _adarnaHearts;

  Future<void> initialize() => _initialization ??= _loadState();

  Future<void> _loadState() async {
    _preferences = await SharedPreferences.getInstance();
    final rawState = _preferences!.getString(_storageKey);
    if (rawState != null) {
      final decoded = jsonDecode(rawState);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Stored Pilak state must be a JSON object.',
        );
      }
      final balance = decoded['balance'];
      final purchased = decoded['purchasedItemIds'];
      if (balance is! int || balance < 0 || purchased is! List) {
        throw const FormatException('Stored Pilak state is invalid.');
      }
      _balance = balance;
      _purchasedItemIds
        ..clear()
        ..addAll(purchased.whereType<String>());
      _activeThemeId = decoded['activeThemeId'] as String?;
      _streakDays = decoded['streakDays'] as int? ?? 0;
      _lastLoginAt = DateTime.tryParse(decoded['lastLoginAt'] as String? ?? '');
      _streakFreezeUntil = DateTime.tryParse(
        decoded['streakFreezeUntil'] as String? ?? '',
      );
      _quizDecayResetCredits = decoded['quizDecayResetCredits'] as int? ?? 0;
      _readingDate = decoded['readingDate'] as String?;
      _readingMinutesToday = decoded['readingMinutesToday'] as int? ?? 0;
      _adarnaModeEnabled = decoded['adarnaModeEnabled'] as bool? ?? false;
      _adarnaHearts = (decoded['adarnaHearts'] as int? ?? 3).clamp(0, 3);
      _transactions
        ..clear()
        ..addAll(_mapList(decoded['pilakTransactions']));
      final readingHistory = decoded['readingHistory'];
      if (readingHistory is Map) {
        _readingHistory
          ..clear()
          ..addEntries(
            readingHistory.entries
                .where((entry) => entry.value is int)
                .map(
                  (entry) => MapEntry(entry.key.toString(), entry.value as int),
                ),
          );
      }
      _loginHistory
        ..clear()
        ..addAll((decoded['loginHistory'] as List? ?? []).whereType<String>());
      _longestStreak = decoded['longestStreak'] as int? ?? _streakDays;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveState() async {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('PilakService must be initialized before saving.');
    }
    final state = {
      'balance': _balance,
      'purchasedItemIds': _purchasedItemIds.toList()..sort(),
      'activeThemeId': _activeThemeId,
      'streakDays': _streakDays,
      'lastLoginAt': _lastLoginAt?.toIso8601String(),
      'streakFreezeUntil': _streakFreezeUntil?.toIso8601String(),
      'quizDecayResetCredits': _quizDecayResetCredits,
      'readingDate': _readingDate,
      'readingMinutesToday': _readingMinutesToday,
      'adarnaModeEnabled': _adarnaModeEnabled,
      'adarnaHearts': _adarnaHearts,
      'pilakTransactions': _transactions,
      'readingHistory': _readingHistory,
      'loginHistory': _loginHistory,
      'longestStreak': _longestStreak,
    };
    if (!await preferences.setString(_storageKey, jsonEncode(state))) {
      throw StateError('Could not persist the Pilak account state.');
    }
  }

  List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
  }

  void _addTransaction(
    int delta,
    String category, {
    DateTime? at,
    String? label,
    int? attempt,
  }) {
    _transactions.add({
      'date': (at ?? DateTime.now()).toIso8601String(),
      'delta': delta,
      'balance': _balance,
      'category': category,
      if (label case final String labelValue) 'label': labelValue,
      if (attempt case final int attemptValue) 'attempt': attemptValue,
    });
    if (_transactions.length > 2000) {
      _transactions.removeRange(0, _transactions.length - 2000);
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _transactionTail = _transactionTail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<bool> purchase(String productId) async {
    await initialize();
    return _serialized(() async {
      final product = pilakProductById(productId);
      if (product == null) throw ArgumentError.value(productId, 'productId');
      final repeatable =
          productId == 'streak_freeze' || productId == 'quiz_decay_reset';
      if (!repeatable && _purchasedItemIds.contains(productId)) return false;
      if (_balance < product.price) return false;

      final previousBalance = _balance;
      final wasPurchased = _purchasedItemIds.contains(productId);
      final previousTheme = _activeThemeId;
      final previousCredits = _quizDecayResetCredits;
      final previousFreeze = _streakFreezeUntil;
      final previousTransactions = List<Map<String, Object?>>.of(_transactions);
      _balance -= product.price;
      _addTransaction(-product.price, 'marketplace');
      _purchasedItemIds.add(productId);
      if (product.themeId != null) _activeThemeId = product.themeId;
      if (productId == 'streak_freeze') {
        _streakFreezeUntil = DateTime.now().add(_hours24);
      } else if (productId == 'quiz_decay_reset') {
        _quizDecayResetCredits++;
      }
      try {
        await _saveState();
      } catch (_) {
        _balance = previousBalance;
        if (!wasPurchased) _purchasedItemIds.remove(productId);
        _activeThemeId = previousTheme;
        _quizDecayResetCredits = previousCredits;
        _streakFreezeUntil = previousFreeze;
        _transactions
          ..clear()
          ..addAll(previousTransactions);
        rethrow;
      }
      notifyListeners();
      AppFeedback.show('Purchased ${product.name} for ${product.price} Pilak.');
      return true;
    });
  }

  bool owns(String productId) => _purchasedItemIds.contains(productId);

  Future<void> setAdarnaModeEnabled(bool enabled) async {
    await initialize();
    await _serialized(() async {
      if (_adarnaModeEnabled == enabled) return;
      final previous = _adarnaModeEnabled;
      _adarnaModeEnabled = enabled;
      try {
        await _saveState();
      } catch (_) {
        _adarnaModeEnabled = previous;
        rethrow;
      }
      notifyListeners();
      AppFeedback.show(enabled ? 'Adarna Mode is on.' : 'Adarna Mode is off.');
    });
  }

  Future<bool> consumeAdarnaSearchHeart() async {
    await initialize();
    return _serialized(() async {
      if (!_adarnaModeEnabled) return true;
      if (_adarnaHearts == 0) return false;
      final previousHearts = _adarnaHearts;
      _adarnaHearts--;
      try {
        await _saveState();
      } catch (_) {
        _adarnaHearts = previousHearts;
        rethrow;
      }
      notifyListeners();
      AppFeedback.show('Heart used. $_adarnaHearts of 3 hearts remaining.');
      return true;
    });
  }

  Future<void> restoreAdarnaHeartsForTesting() async {
    await initialize();
    await _serialized(() async {
      final previousHearts = _adarnaHearts;
      _adarnaHearts = 3;
      try {
        await _saveState();
      } catch (_) {
        _adarnaHearts = previousHearts;
        rethrow;
      }
      notifyListeners();
      AppFeedback.show('Adarna hearts restored to 3.');
    });
  }

  Future<void> setBalanceForTesting(int balance) async {
    if (balance < 0) {
      throw ArgumentError.value(balance, 'balance', 'Must not be negative.');
    }
    await initialize();
    await _serialized(() async {
      final previousBalance = _balance;
      final previousTransactions = List<Map<String, Object?>>.of(_transactions);
      _balance = balance;
      _addTransaction(balance - previousBalance, 'developer_adjustment');
      try {
        await _saveState();
      } catch (_) {
        _balance = previousBalance;
        _transactions
          ..clear()
          ..addAll(previousTransactions);
        rethrow;
      }
      notifyListeners();
      AppFeedback.show('Pilak balance set to $balance.');
    });
  }

  Future<bool> activateTheme(String productId) async {
    await initialize();
    return _serialized(() async {
      final product = pilakProductById(productId);
      if (product?.themeId == null || !owns(productId)) return false;
      final previousTheme = _activeThemeId;
      _activeThemeId = product!.themeId;
      try {
        await _saveState();
      } catch (_) {
        _activeThemeId = previousTheme;
        rethrow;
      }
      notifyListeners();
      return true;
    });
  }

  Future<int> completeQuiz({
    required String activityType,
    required int score,
    required int maxScore,
    required String details,
  }) async {
    await initialize();
    if (score < 0 || maxScore < 0 || score > maxScore) {
      throw ArgumentError('Quiz score must be between zero and max score.');
    }
    return _serialized(() async {
      final attemptsBefore = await DatabaseHelper.instance
          .countActivityAttempts(
            activityType,
            since: DateTime.now().subtract(_hours24),
          );
      final isAdarnaFirstTry =
          _adarnaModeEnabled &&
          await DatabaseHelper.instance.countActivityAttempts(activityType) ==
              0;
      final resetUsed = _quizDecayResetCredits > 0;
      final pilak = calculateAdarnaQuizPilak(
        score,
        resetUsed ? 0 : attemptsBefore + 1,
        adarnaModeEnabled: _adarnaModeEnabled,
      );
      final previousBalance = _balance;
      final previousCredits = _quizDecayResetCredits;
      final previousHearts = _adarnaHearts;
      final previousTransactions = List<Map<String, Object?>>.of(_transactions);
      if (_adarnaModeEnabled &&
          shouldEarnAdarnaHeart(
            score: score,
            maxScore: maxScore,
            firstTry: isAdarnaFirstTry,
          )) {
        _adarnaHearts = math.min(3, _adarnaHearts + 1);
      }
      try {
        await DatabaseHelper.instance.insertActivity(
          type: activityType,
          score: score,
          maxScore: maxScore,
          details: details,
        );
        _balance += pilak;
        _addTransaction(
          pilak,
          'quiz',
          label: activityType,
          attempt: attemptsBefore + 1,
        );
        if (resetUsed) _quizDecayResetCredits--;
        await _saveState();
      } catch (_) {
        _balance = previousBalance;
        _quizDecayResetCredits = previousCredits;
        _adarnaHearts = previousHearts;
        _transactions
          ..clear()
          ..addAll(previousTransactions);
        rethrow;
      }
      notifyListeners();
      AppFeedback.show('Quiz complete: $score/$maxScore. Earned $pilak Pilak.');
      if (_adarnaHearts > previousHearts) {
        AppFeedback.show('You earned a heart! $_adarnaHearts of 3 hearts.');
      }
      AppFeedback.showBadges(
        DatabaseHelper.instance.takeNewlyUnlockedRewards(),
      );
      return pilak;
    });
  }

  Future<int> rewardActiveReading(int minutes) async {
    await initialize();
    if (minutes < 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must not be negative.');
    }
    return _serialized(() async {
      final today = _dateKey(DateTime.now());
      final previousDate = _readingDate;
      final previousMinutes = _readingMinutesToday;
      final previousBalance = _balance;
      final previousHistoryValue = _readingHistory[today];
      final previousTransactions = List<Map<String, Object?>>.of(_transactions);
      if (_readingDate != today) {
        _readingDate = today;
        _readingMinutesToday = 0;
      }
      final oldReward = calculateReadingPilak(_readingMinutesToday);
      _readingMinutesToday += minutes;
      _readingHistory[today] = _readingMinutesToday;
      final reward = calculateReadingPilak(_readingMinutesToday) - oldReward;
      _balance += reward;
      if (reward > 0) _addTransaction(reward, 'reading');
      try {
        await _saveState();
      } catch (_) {
        _readingDate = previousDate;
        _readingMinutesToday = previousMinutes;
        _balance = previousBalance;
        if (previousHistoryValue == null) {
          _readingHistory.remove(today);
        } else {
          _readingHistory[today] = previousHistoryValue;
        }
        _transactions
          ..clear()
          ..addAll(previousTransactions);
        rethrow;
      }
      notifyListeners();
      if (reward > 0) {
        AppFeedback.show('You earned $reward Pilak from reading.');
      }
      return reward;
    });
  }

  Future<int> recordDailyLogin({DateTime? at}) async {
    await initialize();
    return _serialized(() async {
      final now = at ?? DateTime.now();
      final previousLogin = _lastLoginAt;
      final previousStreak = _streakDays;
      final previousFreeze = _streakFreezeUntil;
      final previousLongestStreak = _longestStreak;
      final previousLoginHistory = List<String>.of(_loginHistory);
      if (previousLogin != null && _dateKey(previousLogin) == _dateKey(now)) {
        return 0;
      }
      if (previousLogin == null) {
        _streakDays = 1;
      } else {
        final elapsedDays = DateTime(now.year, now.month, now.day)
            .difference(
              DateTime(
                previousLogin.year,
                previousLogin.month,
                previousLogin.day,
              ),
            )
            .inDays;
        if (elapsedDays == 1) {
          _streakDays++;
        } else if (elapsedDays > 1 && hasActiveStreakFreeze) {
          _streakFreezeUntil = null;
        } else {
          _streakDays = 1;
        }
      }
      _lastLoginAt = now;
      _longestStreak = math.max(_longestStreak, _streakDays);
      final loginDate = _dateKey(now);
      if (!_loginHistory.contains(loginDate)) {
        _loginHistory.add(loginDate);
        _loginHistory.sort();
      }
      final reward = calculateDailyStreakPilak(_streakDays);
      try {
        await _credit(reward, category: 'streak', at: now);
        return reward;
      } catch (_) {
        _streakDays = previousStreak;
        _lastLoginAt = previousLogin;
        _streakFreezeUntil = previousFreeze;
        _longestStreak = previousLongestStreak;
        _loginHistory
          ..clear()
          ..addAll(previousLoginHistory);
        rethrow;
      }
    });
  }

  Future<void> _credit(
    int amount, {
    required String category,
    DateTime? at,
  }) async {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    final previousBalance = _balance;
    final previousTransactions = List<Map<String, Object?>>.of(_transactions);
    _balance += amount;
    _addTransaction(amount, category, at: at);
    try {
      await _saveState();
    } catch (_) {
      _balance = previousBalance;
      _transactions
        ..clear()
        ..addAll(previousTransactions);
      rethrow;
    }
    notifyListeners();
    if (amount > 0) {
      final source = switch (category) {
        'streak' => 'daily streak',
        _ => category,
      };
      AppFeedback.show('You earned $amount Pilak from your $source.');
    }
  }

  Future<File> exportMaterial(String productId) async {
    await initialize();
    final product = pilakProductById(productId);
    if (product == null || product.category != PilakProductCategory.material) {
      throw ArgumentError.value(productId, 'productId', 'Not a material.');
    }
    if (!owns(productId)) throw StateError('Purchase this material first.');
    final assetPath = product.assetPath;
    if (assetPath == null) throw StateError('This material has no asset file.');

    final bytes = await rootBundle.load(assetPath);
    final directory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(path.join(directory.path, 'marketplace'));
    await exportDirectory.create(recursive: true);
    final file = File(
      path.join(exportDirectory.path, path.basename(assetPath)),
    );
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    return file;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
