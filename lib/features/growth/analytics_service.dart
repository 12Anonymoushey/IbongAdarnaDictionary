import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import '../pilak/pilak_service.dart';

class GrowthAnalytics {
  const GrowthAnalytics({
    required this.generalInference,
    required this.quizInference,
    required this.readingInference,
    required this.quizScoresLastSevenDays,
    required this.chapterRangeLabels,
    required this.chapterRangeAverages,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.quizPilakByWeek,
    required this.decayPilakByAttempt,
    required this.readingMinutesLastSevenDays,
    required this.searchVolumeLastSevenDays,
    required this.activityDistribution,
    required this.streakHistory,
    required this.currentStreak,
    required this.longestStreak,
    required this.pilakBalanceLastThirtyDays,
    required this.averageQuizScore,
    required this.quizCount,
    required this.searchesLastSevenDays,
    required this.totalReadingMinutes,
    required this.currentBalance,
    required this.hasReadingTimer,
  });

  final String generalInference;
  final String quizInference;
  final String readingInference;
  final List<double> quizScoresLastSevenDays;
  final List<String> chapterRangeLabels;
  final List<double> chapterRangeAverages;
  final int correctAnswers;
  final int incorrectAnswers;
  final List<int> quizPilakByWeek;
  final List<double> decayPilakByAttempt;
  final List<double> readingMinutesLastSevenDays;
  final List<int> searchVolumeLastSevenDays;
  final List<int> activityDistribution;
  final List<int> streakHistory;
  final int currentStreak;
  final int longestStreak;
  final List<double> pilakBalanceLastThirtyDays;
  final double averageQuizScore;
  final int quizCount;
  final int searchesLastSevenDays;
  final int totalReadingMinutes;
  final int currentBalance;
  final bool hasReadingTimer;
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();
  static const _searchHistoryKey = 'dictionary_search_history';

  Future<void> recordVocabularyInteraction(String term) async {
    final normalized = term
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    if (normalized.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final history = _readSearchHistory(
      preferences.getString(_searchHistoryKey),
    );
    final today = _dateKey(DateTime.now());
    final todayTerms = (history[today] ?? <String>[]).toSet()..add(normalized);
    history[today] = todayTerms.toList()..sort();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    history.removeWhere((date, _) {
      final parsed = DateTime.tryParse(date);
      return parsed == null || parsed.isBefore(cutoff);
    });
    if (!await preferences.setString(_searchHistoryKey, jsonEncode(history))) {
      throw StateError('Could not save dictionary search analytics.');
    }
  }

  Future<GrowthAnalytics> load() async {
    final activities = await DatabaseHelper.instance.getActivities();
    final preferences = await SharedPreferences.getInstance();
    final economy = _readObject(preferences.getString('pilak_economy_state'));
    final searchHistory = _readSearchHistory(
      preferences.getString(_searchHistoryKey),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List<DateTime>.generate(
      30,
      (index) => today.subtract(Duration(days: 29 - index)),
    );
    final weekDays = days.sublist(23);
    final previousWeek = days.sublist(16, 23);
    final parsedActivities = _quizActivities(activities);
    final currentAverage = _average(
      parsedActivities
          .where(
            (quiz) => _inRange(
              quiz.date,
              today.subtract(const Duration(days: 6)),
              today,
            ),
          )
          .map((quiz) => quiz.ratio),
    );
    final previousAverage = _average(
      parsedActivities
          .where(
            (quiz) => _inRange(
              quiz.date,
              today.subtract(const Duration(days: 13)),
              today.subtract(const Duration(days: 7)),
            ),
          )
          .map((quiz) => quiz.ratio),
    );
    final currentCount = parsedActivities
        .where(
          (quiz) => _inRange(
            quiz.date,
            today.subtract(const Duration(days: 6)),
            today,
          ),
        )
        .length;
    final previousCount = parsedActivities
        .where(
          (quiz) => _inRange(
            quiz.date,
            today.subtract(const Duration(days: 13)),
            today.subtract(const Duration(days: 7)),
          ),
        )
        .length;
    final currentStreak = economy['streakDays'] as int? ?? 0;

    final scoresByDay = _groupDaily<double>(
      parsedActivities,
      (quiz) => quiz.ratio * 100,
    );
    final chapterSums = List<double>.filled(5, 0);
    final chapterCounts = List<int>.filled(5, 0);
    var correct = 0;
    var incorrect = 0;
    for (final quiz in parsedActivities) {
      if (quiz.kabanata != null &&
          quiz.kabanata! >= 1 &&
          quiz.kabanata! <= 46) {
        final rangeIndex = (quiz.kabanata! - 1) ~/ 10;
        chapterSums[rangeIndex] += quiz.ratio * 100;
        chapterCounts[rangeIndex]++;
      }
      correct += quiz.correct;
      incorrect += quiz.incorrect;
    }
    final chapterLabels = List.generate(5, (index) {
      final start = index * 10 + 1;
      final end = math.min(start + 9, 46);
      return '$start-$end';
    });
    final chapterAverages = List.generate(
      5,
      (index) => chapterCounts[index] == 0
          ? 0.0
          : chapterSums[index] / chapterCounts[index],
    );

    final transactions = _mapList(economy['pilakTransactions']);
    final quizPilakByDate = _sumTransactionsByDate(
      transactions.where((entry) => entry['category'] == 'quiz'),
    );
    final weeklyQuizPilak = [
      previousWeek.fold<int>(
        0,
        (sum, day) => sum + (quizPilakByDate[_dateKey(day)] ?? 0),
      ),
      weekDays.fold<int>(
        0,
        (sum, day) => sum + (quizPilakByDate[_dateKey(day)] ?? 0),
      ),
    ];
    final decayAverages = _decayImpact(parsedActivities, transactions);

    final readingHistory = _intMap(economy['readingHistory']);
    final readingMinutes = [
      for (final day in weekDays)
        (readingHistory[_dateKey(day)] ?? 0).toDouble(),
    ];
    final searches = [
      for (final day in weekDays)
        (searchHistory[_dateKey(day)] ?? const <String>[]).length,
    ];
    final previousReadingMinutes = previousWeek.fold<int>(
      0,
      (sum, day) => sum + (readingHistory[_dateKey(day)] ?? 0),
    );
    final currentReadingMinutes = weekDays.fold<int>(
      0,
      (sum, day) => sum + (readingHistory[_dateKey(day)] ?? 0),
    );
    final previousSearches = previousWeek.fold<int>(
      0,
      (sum, day) =>
          sum + (searchHistory[_dateKey(day)] ?? const <String>[]).length,
    );
    final currentSearches = searches.fold<int>(0, (a, b) => a + b);
    final generalInference = compareLastSevenDays(
      currentCount: currentCount,
      previousCount: previousCount,
      currentAverage: currentAverage,
      previousAverage: previousAverage,
      streak: currentStreak,
      currentReadingMinutes: currentReadingMinutes,
      previousReadingMinutes: previousReadingMinutes,
      currentSearches: currentSearches,
      previousSearches: previousSearches,
    );
    final readingTotal = readingHistory.values.fold<int>(0, (a, b) => a + b);
    final loginHistory = (economy['loginHistory'] as List? ?? [])
        .whereType<String>()
        .toSet();
    final streakHistory = [
      for (final day in days) loginHistory.contains(_dateKey(day)) ? 1 : 0,
    ];
    final longestStreak = math.max(
      economy['longestStreak'] as int? ?? currentStreak,
      _longestConsecutiveStreak(loginHistory),
    );

    final weekDateKeys = weekDays.map(_dateKey).toSet();
    final marketplaceTransactions = transactions.where((entry) {
      final date = DateTime.tryParse(entry['date'] as String? ?? '');
      return entry['category'] == 'marketplace' &&
          date != null &&
          weekDateKeys.contains(_dateKey(date));
    });
    final marketplaceCount = marketplaceTransactions.length;
    final weeklySearches = searches.fold<int>(0, (a, b) => a + b);
    final quizzesTracked = parsedActivities
        .where(
          (quiz) =>
              quiz.date != null && weekDateKeys.contains(_dateKey(quiz.date!)),
        )
        .length;
    final weeklyReadingMinutes = weekDays.fold<int>(
      0,
      (sum, day) => sum + (readingHistory[_dateKey(day)] ?? 0),
    );
    final distributionTotal =
        weeklySearches +
        weeklyReadingMinutes +
        quizzesTracked +
        marketplaceCount;
    final distribution = distributionTotal == 0
        ? [0, 0, 0]
        : [
            weeklySearches + weeklyReadingMinutes,
            quizzesTracked,
            marketplaceCount,
          ];

    final dailyBalances = _balancesByDay(transactions, days, economy);
    final scoreAverage = parsedActivities.isEmpty
        ? 0.0
        : parsedActivities.map((quiz) => quiz.ratio).reduce((a, b) => a + b) /
              parsedActivities.length;

    return GrowthAnalytics(
      generalInference: generalInference,
      quizInference: _quizInference(parsedActivities, decayAverages),
      readingInference: _readingInference(readingHistory, searches),
      quizScoresLastSevenDays: [
        for (final day in weekDays)
          _average(scoresByDay[_dateKey(day)] ?? const <double>[]),
      ],
      chapterRangeLabels: chapterLabels,
      chapterRangeAverages: chapterAverages,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      quizPilakByWeek: weeklyQuizPilak,
      decayPilakByAttempt: decayAverages,
      readingMinutesLastSevenDays: readingMinutes,
      searchVolumeLastSevenDays: searches,
      activityDistribution: distribution,
      streakHistory: streakHistory,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      pilakBalanceLastThirtyDays: dailyBalances,
      averageQuizScore: scoreAverage,
      quizCount: parsedActivities.length,
      searchesLastSevenDays: weeklySearches,
      totalReadingMinutes: readingTotal,
      currentBalance: economy['balance'] as int? ?? 0,
      hasReadingTimer: readingTotal > 0,
    );
  }

  static String compareLastSevenDays({
    required int currentCount,
    required int previousCount,
    required double currentAverage,
    required double previousAverage,
    required int streak,
    int currentReadingMinutes = 0,
    int previousReadingMinutes = 0,
    int currentSearches = 0,
    int previousSearches = 0,
  }) {
    if (streak == 0 && currentCount + previousCount > 0) {
      return '📉 Your streak broke, but every new study session is a chance to build it again.';
    }
    if (currentReadingMinutes > previousReadingMinutes) {
      final increase = previousReadingMinutes == 0
          ? 100
          : ((currentReadingMinutes - previousReadingMinutes) /
                    previousReadingMinutes *
                    100)
                .round();
      if (currentAverage > previousAverage) {
        return '🔥 You read $increase% more this week and increased your average quiz score!';
      }
      return '📖 You read $increase% more this week. Keep building your vocabulary!';
    }
    if (currentSearches > previousSearches && previousSearches > 0) {
      final increase =
          ((currentSearches - previousSearches) / previousSearches * 100)
              .round();
      return '📚 You explored $increase% more unique dictionary words this week.';
    }
    if (previousCount == 0 && currentCount == 0) {
      return 'Complete a quiz or explore dictionary words to start seeing your progress.';
    }
    final countChange = previousCount == 0
        ? (currentCount > 0 ? 100.0 : 0.0)
        : (currentCount - previousCount) / previousCount * 100;
    final scoreChange = currentAverage - previousAverage;
    if (countChange >= 15 && scoreChange >= 0.03) {
      return '🔥 You completed ${countChange.round()}% more quizzes this week and your average score improved.';
    }
    if (countChange >= 15) {
      return '🔥 You completed ${countChange.round()}% more quizzes this week. Keep the momentum going!';
    }
    if (scoreChange >= 0.05) {
      return '📈 Your average quiz score improved by ${(scoreChange * 100).round()} percentage points this week.';
    }
    if (countChange <= -20) {
      return '📉 You completed fewer quizzes this week. A short daily session can help rebuild your routine.';
    }
    return '📚 You completed $currentCount quizzes this week and your current study streak is $streak ${streak == 1 ? 'day' : 'days'}.';
  }

  static List<_ParsedQuiz> _quizActivities(
    List<Map<String, Object?>> activities,
  ) => activities
      .where((activity) {
        final details = _readObject(activity['details'] as String?);
        return details['quizMode'] is String;
      })
      .map(_ParsedQuiz.fromActivity)
      .toList();

  static Map<String, List<T>> _groupDaily<T>(
    List<_ParsedQuiz> quizzes,
    T Function(_ParsedQuiz quiz) value,
  ) {
    final result = <String, List<T>>{};
    for (final quiz in quizzes) {
      if (quiz.date == null) continue;
      result.putIfAbsent(_dateKey(quiz.date!), () => []).add(value(quiz));
    }
    return result;
  }

  static List<double> _decayImpact(
    List<_ParsedQuiz> quizzes,
    List<Map<String, Object?>> transactions,
  ) {
    final recorded = transactions.where(
      (transaction) =>
          transaction['category'] == 'quiz' && transaction['attempt'] is int,
    );
    if (recorded.isNotEmpty) {
      final yields = List<List<int>>.generate(4, (_) => []);
      for (final transaction in recorded) {
        final attempt = transaction['attempt'] as int;
        yields[math.min(math.max(attempt - 1, 0), 3)].add(
          transaction['delta'] as int? ?? 0,
        );
      }
      final averageScore = _average(
        quizzes.map((quiz) => quiz.score.toDouble()),
      );
      final observedFirstYield = yields[0].isEmpty
          ? null
          : yields[0].reduce((a, b) => a + b) / yields[0].length;
      final baseFirstYield = calculateQuizPilak(averageScore.floor(), 1);
      final rewardScale = observedFirstYield == null || baseFirstYield == 0
          ? 1.0
          : observedFirstYield / baseFirstYield;
      return [
        for (var index = 0; index < yields.length; index++)
          yields[index].isEmpty
              ? calculateQuizPilak(averageScore.floor(), index + 1).toDouble() *
                    rewardScale
              : yields[index].reduce((a, b) => a + b) / yields[index].length,
      ];
    }

    final sorted = [...quizzes]
      ..sort(
        (a, b) => (a.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          b.date ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    final yields = List<List<int>>.generate(4, (_) => []);
    for (var index = 0; index < sorted.length; index++) {
      final quiz = sorted[index];
      final date = quiz.date;
      if (date == null) continue;
      final attempts = sorted
          .take(index)
          .where(
            (previous) =>
                previous.name == quiz.name &&
                previous.date != null &&
                date.difference(previous.date!) <= const Duration(hours: 24),
          )
          .length;
      final bucket = math.min(attempts, 3);
      yields[bucket].add(calculateQuizPilak(quiz.score, attempts + 1));
    }
    final averageScore = _average(quizzes.map((quiz) => quiz.score.toDouble()));
    return [
      for (var index = 0; index < yields.length; index++)
        yields[index].isEmpty
            ? calculateQuizPilak(averageScore.floor(), index + 1).toDouble()
            : yields[index].reduce((a, b) => a + b) / yields[index].length,
    ];
  }

  static String _quizInference(List<_ParsedQuiz> quizzes, List<double> decay) {
    if (quizzes.isEmpty) {
      return 'Complete a quiz to unlock performance insights.';
    }
    final average =
        quizzes.map((quiz) => quiz.ratio).reduce((a, b) => a + b) /
        quizzes.length;
    if (decay[0] > 0 && decay[3] < decay[0]) {
      return 'Scores degrade after repeated attempts; the Pilak decay formula also reduces repeat rewards.';
    }
    if (average < 0.6) {
      return 'Review missed terms before your next quiz to strengthen retention.';
    }
    return 'Your historical quiz average is ${(average * 100).round()}%.';
  }

  static String _readingInference(
    Map<String, int> readingHistory,
    List<int> searches,
  ) {
    final hasReading = readingHistory.values.any((minutes) => minutes > 0);
    final searchCount = searches.fold<int>(0, (a, b) => a + b);
    if (!hasReading) {
      return searchCount == 0
          ? 'Reading-time tracking is not active yet; your dictionary and quiz activity will appear here.'
          : 'You explored $searchCount unique dictionary terms this week. Reading time is not being recorded yet.';
    }
    final minutes = readingHistory.values.fold<int>(0, (a, b) => a + b);
    return 'You have logged $minutes minutes of active reading.';
  }

  static Map<String, int> _sumTransactionsByDate(
    Iterable<Map<String, Object?>> transactions,
  ) {
    final result = <String, int>{};
    for (final transaction in transactions) {
      final date = DateTime.tryParse(transaction['date'] as String? ?? '');
      if (date == null) continue;
      final key = _dateKey(date);
      result[key] = (result[key] ?? 0) + (transaction['delta'] as int? ?? 0);
    }
    return result;
  }

  static List<double> _balancesByDay(
    List<Map<String, Object?>> transactions,
    List<DateTime> days,
    Map<String, dynamic> economy,
  ) {
    final ordered = [...transactions]
      ..sort(
        (a, b) =>
            (DateTime.tryParse(a['date'] as String? ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  DateTime.tryParse(b['date'] as String? ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0),
                ),
      );
    if (ordered.isEmpty) {
      return List<double>.filled(
        days.length,
        (economy['balance'] as int? ?? 0).toDouble(),
      );
    }
    final firstBalance = ordered.first['balance'] as int? ?? 0;
    final firstDelta = ordered.first['delta'] as int? ?? 0;
    var balance = firstBalance - firstDelta;
    var transactionIndex = 0;
    final result = <double>[];
    for (final day in days) {
      final end = day.add(const Duration(days: 1));
      while (transactionIndex < ordered.length) {
        final date = DateTime.tryParse(
          ordered[transactionIndex]['date'] as String? ?? '',
        );
        if (date == null || !date.isBefore(end)) break;
        balance = ordered[transactionIndex]['balance'] as int? ?? balance;
        transactionIndex++;
      }
      result.add(balance.toDouble());
    }
    return result;
  }

  static int _longestConsecutiveStreak(Set<String> loginDates) {
    final dates =
        loginDates
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map((date) => DateTime.utc(date.year, date.month, date.day))
            .toList()
          ..sort();
    var longest = 0;
    var current = 0;
    DateTime? previous;
    for (final date in dates) {
      if (previous != null && date.difference(previous).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      longest = math.max(longest, current);
      previous = date;
    }
    return longest;
  }

  static bool _inRange(DateTime? date, DateTime first, DateTime last) {
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(first) && !day.isAfter(last);
  }

  static double _average(Iterable<double> values) {
    final list = values.toList();
    return list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
  }

  static Map<String, dynamic> _readObject(String? value) {
    if (value == null) return {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  static List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) return [];
    return value.whereType<Map>().map(Map<String, Object?>.from).toList();
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is int) entry.key.toString(): entry.value as int,
    };
  }

  static Map<String, List<String>> _readSearchHistory(String? value) {
    final decoded = _readObject(value);
    return {
      for (final entry in decoded.entries)
        if (entry.value is List)
          entry.key: (entry.value as List).whereType<String>().toList(),
    };
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _ParsedQuiz {
  const _ParsedQuiz({
    required this.name,
    required this.score,
    required this.ratio,
    required this.correct,
    required this.incorrect,
    required this.date,
    required this.kabanata,
  });

  factory _ParsedQuiz.fromActivity(Map<String, Object?> activity) {
    final score = activity['score'] as int? ?? 0;
    final maxScore = (activity['max_score'] as int? ?? 0);
    final details = AnalyticsService._readObject(
      activity['details'] as String?,
    );
    var correct = 0;
    var incorrect = 0;
    final questions = details['questions'];
    if (questions is List) {
      for (final item in questions.whereType<Map>()) {
        if (item['correct'] == true) {
          correct++;
        } else if (item['correct'] == false) {
          incorrect++;
        }
      }
    }
    if (correct + incorrect == 0 && maxScore > 0) {
      correct = score;
      incorrect = math.max(0, maxScore - score);
    }
    final kabanataValue = details['kabanata'];
    return _ParsedQuiz(
      name: activity['type'] as String? ?? '',
      score: score,
      ratio: maxScore <= 0 ? 0 : (score / maxScore).clamp(0.0, 1.0),
      correct: correct,
      incorrect: incorrect,
      date: DateTime.tryParse(activity['date'] as String? ?? ''),
      kabanata: kabanataValue is int ? kabanataValue : null,
    );
  }

  final String name;
  final int score;
  final double ratio;
  final int correct;
  final int incorrect;
  final DateTime? date;
  final int? kabanata;
}
