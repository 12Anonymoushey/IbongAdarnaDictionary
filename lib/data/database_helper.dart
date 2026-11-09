import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const String _databaseName = 'dictionary.db';
  static const int _databaseVersion = 3;
  static const String _bundledWordsVersion = '2';
  Future<Database>? _databaseFuture;
  final List<String> _pendingRewardUnlocks = [];

  Future<Database> get database => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = join(directory.path, _databaseName);
    final databaseFile = File(databasePath);

    if (!await databaseFile.exists()) {
      await databaseFile.parent.create(recursive: true);
      final bundledDatabase = await rootBundle.load('assets/dictionary.db');
      await databaseFile.writeAsBytes(
        bundledDatabase.buffer.asUint8List(
          bundledDatabase.offsetInBytes,
          bundledDatabase.lengthInBytes,
        ),
        flush: true,
      );
    }

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) => _ensureSchema(db),
      onOpen: _ensureSchema,
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term TEXT NOT NULL,
        definition TEXT NOT NULL,
        kabanata INTEGER,
        part_of_speech TEXT,
        synonyms TEXT,
        antonyms TEXT,
        sample_sentence TEXT,
        image_path TEXT,
        is_saved INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        details TEXT NOT NULL DEFAULT '',
        max_score INTEGER NOT NULL DEFAULT 100,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await _createSupportingTables(db);
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term TEXT NOT NULL,
        definition TEXT NOT NULL,
        kabanata INTEGER,
        part_of_speech TEXT,
        synonyms TEXT,
        antonyms TEXT,
        sample_sentence TEXT,
        image_path TEXT,
        is_saved INTEGER NOT NULL DEFAULT 0
      )
    ''');
    final wordColumns = await db.rawQuery('PRAGMA table_info(words)');
    final existingWordColumns = wordColumns
        .map((row) => row['name'] as String)
        .toSet();
    final wordAdditions = <String, String>{
      'kabanata': 'INTEGER',
      'part_of_speech': 'TEXT',
      'synonyms': 'TEXT',
      'antonyms': 'TEXT',
      'sample_sentence': 'TEXT',
      'image_path': 'TEXT',
      'is_saved': 'INTEGER NOT NULL DEFAULT 0',
    };
    for (final entry in wordAdditions.entries) {
      if (!existingWordColumns.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE words ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        details TEXT NOT NULL DEFAULT '',
        max_score INTEGER NOT NULL DEFAULT 100,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    final columns = await db.rawQuery('PRAGMA table_info(activities)');
    final existingColumns = columns.map((row) => row['name'] as String).toSet();
    final additions = <String, String>{
      'details': "TEXT NOT NULL DEFAULT ''",
      'max_score': 'INTEGER NOT NULL DEFAULT 100',
      'created_at': 'TEXT',
      'updated_at': 'TEXT',
    };
    for (final entry in additions.entries) {
      if (!existingColumns.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE activities ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
    await _createSupportingTables(db);
  }

  Future<void> _createSupportingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reward_definitions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        metric TEXT NOT NULL,
        threshold INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_rewards (
        reward_id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL,
        FOREIGN KEY (reward_id) REFERENCES reward_definitions(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quiz_drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mode TEXT NOT NULL,
        source TEXT NOT NULL,
        kabanata_number INTEGER,
        questions TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    final batch = db.batch();
    for (final reward in _rewardDefinitions) {
      batch.insert(
        'reward_definitions',
        reward,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    batch.insert('app_settings', {
      'setting_key': 'speak_word_of_day',
      'setting_value': '0',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('app_settings', {
      'setting_key': 'bundled_words_version',
      'setting_value': '0',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await batch.commit(noResult: true);
    await _syncBundledWords(db);
  }

  Future<void> _syncBundledWords(Database db) async {
    final syncState = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['bundled_words_version'],
      limit: 1,
    );
    if (syncState.isNotEmpty &&
        syncState.first['setting_value'] == _bundledWordsVersion) {
      return;
    }

    final bundledBytes = await rootBundle.load('assets/dictionary.db');
    final temporaryDirectory = await getTemporaryDirectory();
    final bundledFile = File(
      join(temporaryDirectory.path, 'dictionary_seed_sync.db'),
    );
    await bundledFile.writeAsBytes(
      bundledBytes.buffer.asUint8List(
        bundledBytes.offsetInBytes,
        bundledBytes.lengthInBytes,
      ),
      flush: true,
    );

    Database? bundledDatabase;
    try {
      bundledDatabase = await openDatabase(bundledFile.path, readOnly: true);
      final bundledColumns = (await bundledDatabase.rawQuery(
        'PRAGMA table_info(words)',
      )).map((row) => row['name'] as String).toSet();
      const importedColumns = [
        'term',
        'definition',
        'kabanata',
        'part_of_speech',
        'synonyms',
        'antonyms',
        'sample_sentence',
        'image_path',
      ];
      final selectedColumns = importedColumns
          .where(bundledColumns.contains)
          .toList();
      final bundledWords = await bundledDatabase.query(
        'words',
        columns: selectedColumns,
      );

      await db.transaction((transaction) async {
        final existingWords = await transaction.query(
          'words',
          columns: [
            'term',
            'kabanata',
            'part_of_speech',
            'synonyms',
            'antonyms',
            'sample_sentence',
          ],
        );
        final existingByTerm = {
          for (final word in existingWords)
            _normalizeWordTerm(word['term'] as String): word,
        };

        for (final word in bundledWords) {
          final term = word['term'] as String;
          final normalizedTerm = _normalizeWordTerm(term);
          final existingWord = existingByTerm[normalizedTerm];
          if (existingWord != null) {
            final metadata = <String, Object?>{};
            for (final column in importedColumns.skip(2).take(5)) {
              final currentValue = existingWord[column];
              final bundledValue = word[column];
              if ((currentValue == null ||
                      currentValue.toString().trim().isEmpty) &&
                  bundledValue != null &&
                  bundledValue.toString().trim().isNotEmpty) {
                metadata[column] = bundledValue;
              }
            }
            if (metadata.isNotEmpty) {
              await transaction.update(
                'words',
                metadata,
                where: 'term = ?',
                whereArgs: [existingWord['term']],
              );
            }
            continue;
          }
          await transaction.insert('words', {
            for (final column in selectedColumns) column: word[column],
            'is_saved': 0,
          });
          existingByTerm[normalizedTerm] = word;
        }

        await transaction.update(
          'app_settings',
          {'setting_value': _bundledWordsVersion},
          where: 'setting_key = ?',
          whereArgs: ['bundled_words_version'],
        );
      });
    } finally {
      await bundledDatabase?.close();
      if (await bundledFile.exists()) await bundledFile.delete();
    }
  }

  String _normalizeWordTerm(String term) =>
      term.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static const List<Map<String, Object>> _rewardDefinitions = [
    {
      'id': 'streak_3',
      'title': 'Three-day Streak',
      'description': 'Study on three consecutive days.',
      'metric': 'streak',
      'threshold': 3,
    },
    {
      'id': 'streak_7',
      'title': 'Weekly Scholar',
      'description': 'Study on seven consecutive days.',
      'metric': 'streak',
      'threshold': 7,
    },
    {
      'id': 'streak_30',
      'title': 'Adarna Scholar',
      'description': 'Study on thirty consecutive days.',
      'metric': 'streak',
      'threshold': 30,
    },
    {
      'id': 'activities_10',
      'title': 'Activity Explorer',
      'description': 'Complete ten activities.',
      'metric': 'activity_count',
      'threshold': 10,
    },
    {
      'id': 'score_1000',
      'title': 'Dedicated Learner',
      'description': 'Earn 1,000 activity points.',
      'metric': 'total_score',
      'threshold': 1000,
    },
  ];

  Future<List<Map<String, Object?>>> getWords([String query = '']) async {
    final db = await database;
    if (query.trim().isEmpty) {
      return db.query('words', orderBy: 'term COLLATE NOCASE');
    }
    final escapedQuery = query
        .trim()
        .replaceAll('\\', '\\\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final pattern = '%$escapedQuery%';
    return db.query(
      'words',
      where: "term LIKE ? ESCAPE '\\' OR definition LIKE ? ESCAPE '\\'",
      whereArgs: [pattern, pattern],
      orderBy: 'term COLLATE NOCASE',
    );
  }

  Future<List<Map<String, Object?>>> getWordsByKabanata(
    int kabanata, [
    String query = '',
  ]) async {
    final db = await database;
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return db.query(
        'words',
        where: 'kabanata = ?',
        whereArgs: [kabanata],
        orderBy: 'term COLLATE NOCASE',
      );
    }
    final escapedQuery = trimmedQuery
        .replaceAll('\\', '\\\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final pattern = '%$escapedQuery%';
    return db.query(
      'words',
      where: "kabanata = ? AND (term LIKE ? ESCAPE '\\' OR definition LIKE ? ESCAPE '\\')",
      whereArgs: [kabanata, pattern, pattern],
      orderBy: 'term COLLATE NOCASE',
    );
  }

  Future<Map<String, List<Object>>> getWordFilterOptions() async {
    final db = await database;
    final kabanataRows = await db.rawQuery(
      'SELECT DISTINCT kabanata FROM words '
      'WHERE kabanata IS NOT NULL ORDER BY kabanata',
    );
    final partOfSpeechRows = await db.rawQuery(
      "SELECT DISTINCT part_of_speech FROM words "
      "WHERE part_of_speech IS NOT NULL AND TRIM(part_of_speech) != '' "
      'ORDER BY part_of_speech COLLATE NOCASE',
    );
    return {
      'kabanata': [for (final row in kabanataRows) row['kabanata'] as Object],
      'part_of_speech': [
        for (final row in partOfSpeechRows) row['part_of_speech'] as Object,
      ],
    };
  }

  Future<List<Map<String, Object?>>> getFilteredWords({
    String query = '',
    int? kabanata,
    String? partOfSpeech,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (kabanata != null) {
      conditions.add('kabanata = ?');
      arguments.add(kabanata);
    }
    if (partOfSpeech != null && partOfSpeech.isNotEmpty) {
      conditions.add('part_of_speech = ?');
      arguments.add(partOfSpeech);
    }
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      final escapedQuery = trimmedQuery
          .replaceAll('\\', '\\\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final pattern = '%$escapedQuery%';
      conditions.add(
        "(term LIKE ? ESCAPE '\\' OR definition LIKE ? ESCAPE '\\')",
      );
      arguments
        ..add(pattern)
        ..add(pattern);
    }
    return db.query(
      'words',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'term COLLATE NOCASE',
    );
  }

  Future<Map<String, Object?>?> getWordOfTheDay() async {
    final db = await database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM words',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count == 0) return null;

    final today = DateTime.now();
    final dayNumber = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(2024, 1, 1)).inDays;
    final dayOffset = ((dayNumber % count) + count) % count;
    final rows = await db.query(
      'words',
      orderBy: 'id',
      limit: 1,
      offset: dayOffset,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setWordSaved(int id, bool saved) async {
    final db = await database;
    await db.update(
      'words',
      {'is_saved': saved ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> getSavedWords() async {
    final db = await database;
    return db.query(
      'words',
      where: 'is_saved = 1',
      orderBy: 'term COLLATE NOCASE',
    );
  }

  Future<int> insertActivity({
    required String type,
    required int score,
    required int maxScore,
    required String details,
    DateTime? date,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final activityId = await db.insert('activities', {
      'type': type.trim(),
      'score': score,
      'max_score': maxScore,
      'details': details.trim(),
      'date': (date ?? now).toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await _refreshRewards(db);
    return activityId;
  }

  Future<int> updateActivity({
    required int id,
    required String type,
    required int score,
    required int maxScore,
    required String details,
    DateTime? date,
  }) async {
    final db = await database;
    final result = await db.update(
      'activities',
      {
        'type': type.trim(),
        'score': score,
        'max_score': maxScore,
        'details': details.trim(),
        'date': (date ?? DateTime.now()).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _refreshRewards(db);
    return result;
  }

  Future<int> deleteActivity(int id) async {
    final db = await database;
    final result = await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _refreshRewards(db);
    return result;
  }

  Future<List<Map<String, Object?>>> getActivities() async {
    final db = await database;
    return db.query('activities', orderBy: 'date DESC, id DESC');
  }

  Future<int> countActivityAttempts(String type, {DateTime? since}) async {
    final db = await database;
    final result = since == null
        ? await db.rawQuery(
            'SELECT COUNT(*) AS count FROM activities WHERE type = ?',
            [type],
          )
        : await db.rawQuery(
            'SELECT COUNT(*) AS count FROM activities WHERE type = ? AND date >= ?',
            [type, since.toIso8601String()],
          );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> saveQuizDraft({
    required String name,
    required String mode,
    required String source,
    required String questions,
    int? kabanataNumber,
  }) async {
    final db = await database;
    return db.insert('quiz_drafts', {
      'name': name.trim(),
      'mode': mode,
      'source': source,
      'kabanata_number': kabanataNumber,
      'questions': questions,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getQuizDrafts() async {
    final db = await database;
    return db.query('quiz_drafts', orderBy: 'created_at DESC, id DESC');
  }

  Future<int> deleteQuizDraft(int id) async {
    final db = await database;
    return db.delete('quiz_drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Object?>> getGrowthStats() async {
    final activities = await getActivities();
    final now = DateTime.now();
    final completedDays = <DateTime>{};
    var earnedScore = 0;
    var possibleScore = 0;
    final weekCounts = List<int>.filled(7, 0);

    for (final activity in activities) {
      final date = DateTime.tryParse(activity['date'] as String? ?? '');
      if (date == null) continue;
      final day = DateTime.utc(date.year, date.month, date.day);
      completedDays.add(day);
      earnedScore += (activity['score'] as int?) ?? 0;
      possibleScore += (activity['max_score'] as int?) ?? 100;
      final today = DateTime.utc(now.year, now.month, now.day);
      final daysAgo = today.difference(day).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        weekCounts[6 - daysAgo]++;
      }
    }

    var currentStreak = 0;
    var streakDay = DateTime.utc(now.year, now.month, now.day);
    if (!completedDays.contains(streakDay)) {
      streakDay = streakDay.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(streakDay)) {
      currentStreak++;
      streakDay = streakDay.subtract(const Duration(days: 1));
    }

    final averageScore = possibleScore == 0
        ? 0.0
        : (earnedScore / possibleScore).clamp(0.0, 1.0).toDouble();
    return {
      'activityCount': activities.length,
      'currentStreak': currentStreak,
      'averageScore': averageScore,
      'earnedScore': earnedScore,
      'weeklyActivityCounts': weekCounts,
    };
  }

  Future<List<Map<String, Object?>>> getRewards() async {
    final db = await database;
    await _refreshRewards(db);
    return db.rawQuery('''
      SELECT reward_definitions.*, user_rewards.unlocked_at
      FROM reward_definitions
      LEFT JOIN user_rewards ON reward_definitions.id = user_rewards.reward_id
      ORDER BY reward_definitions.threshold
    ''');
  }

  List<String> takeNewlyUnlockedRewards() {
    final unlocked = List<String>.of(_pendingRewardUnlocks);
    _pendingRewardUnlocks.clear();
    return unlocked;
  }

  Future<void> _refreshRewards(Database db) async {
    final stats = await getGrowthStats();
    final values = <String, int>{
      'streak': stats['currentStreak'] as int,
      'activity_count': stats['activityCount'] as int,
      'total_score': stats['earnedScore'] as int,
    };
    final definitions = await db.query('reward_definitions');
    final existingUnlocks = (await db.query('user_rewards'))
        .map((reward) => reward['reward_id'] as String)
        .toSet();
    final batch = db.batch();
    final newlyUnlocked = <String>[];
    for (final reward in definitions) {
      final metric = reward['metric'] as String;
      final threshold = reward['threshold'] as int;
      if ((values[metric] ?? 0) >= threshold) {
        if (!existingUnlocks.contains(reward['id'])) {
          newlyUnlocked.add(reward['title'] as String);
        }
        batch.insert('user_rewards', {
          'reward_id': reward['id'],
          'unlocked_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    await batch.commit(noResult: true);
    _pendingRewardUnlocks.addAll(newlyUnlocked);
  }

  Future<bool> getSpeakWordOfDaySetting() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['speak_word_of_day'],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['setting_value'] == '1';
  }

  Future<void> setSpeakWordOfDaySetting(bool enabled) async {
    final db = await database;
    await db.insert('app_settings', {
      'setting_key': 'speak_word_of_day',
      'setting_value': enabled ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
