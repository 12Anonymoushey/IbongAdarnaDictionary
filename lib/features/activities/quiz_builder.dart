import 'dart:math';

enum QuizMode { multipleChoice, identification, flashcards }

enum QuizWordSource { freestyle, chooseWords, randomWords, kabanataQuiz }

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.answer,
    this.options = const [],
  });

  final String prompt;
  final String answer;
  final List<String> options;

  Map<String, Object?> toJson() => {
    'prompt': prompt,
    'answer': answer,
    'options': options,
  };

  factory QuizQuestion.fromJson(Map<String, Object?> json) {
    final prompt = json['prompt'];
    final answer = json['answer'];
    final options = json['options'];
    if (prompt is! String || answer is! String || options is! List) {
      throw const FormatException('Saved quiz question is invalid.');
    }
    return QuizQuestion(
      prompt: prompt,
      answer: answer,
      options: options.whereType<String>().toList(growable: false),
    );
  }
}

class QuizBuilder {
  const QuizBuilder._();

  static bool answerMatches(String given, String expected) =>
      _normalize(given) == _normalize(expected);

  static List<Map<String, Object?>> uniqueWords(
    List<Map<String, Object?>> words,
  ) => _uniqueTerms(words);

  static List<Map<String, Object?>> wordsForKabanata(
    List<Map<String, Object?>> words,
    int kabanata,
  ) => _uniqueTerms(
    words.where((word) => word['kabanata'] == kabanata).toList(),
  );

  static List<QuizQuestion> build({
    required QuizMode mode,
    required List<Map<String, Object?>> words,
    List<Map<String, Object?>> dictionaryWords = const [],
    Random? random,
  }) {
    if (words.isEmpty) {
      throw ArgumentError.value(
        words,
        'words',
        'At least one word is required.',
      );
    }

    final generator = random ?? Random();
    final candidates = _uniqueTerms([...dictionaryWords, ...words]);
    final quizWords = _uniqueTerms(words);
    if (quizWords.isEmpty) {
      throw ArgumentError.value(
        words,
        'words',
        'Words need a term and definition.',
      );
    }

    if (mode == QuizMode.multipleChoice && candidates.length < 2) {
      throw ArgumentError(
        'Multiple Choice needs at least two unique dictionary terms.',
      );
    }

    return [
      for (final word in quizWords)
        _buildQuestion(
          mode: mode,
          word: word,
          candidates: candidates,
          random: generator,
        ),
    ];
  }

  static List<Map<String, Object?>> randomWords(
    List<Map<String, Object?>> source,
    int count, {
    Random? random,
  }) {
    final uniqueWords = _uniqueTerms(source);
    if (count < 1 || count > uniqueWords.length) {
      throw RangeError.range(count, 1, uniqueWords.length, 'count');
    }
    final shuffled = List<Map<String, Object?>>.of(uniqueWords)
      ..shuffle(random ?? Random());
    return shuffled.take(count).toList();
  }

  static QuizQuestion _buildQuestion({
    required QuizMode mode,
    required Map<String, Object?> word,
    required List<Map<String, Object?>> candidates,
    required Random random,
  }) {
    final term = (word['term'] as String).trim();
    final definition = (word['definition'] as String).trim();
    if (mode == QuizMode.flashcards) {
      return QuizQuestion(prompt: term, answer: definition);
    }
    if (mode == QuizMode.identification) {
      return QuizQuestion(prompt: definition, answer: term);
    }

    final distractors =
        candidates
            .where(
              (candidate) =>
                  _normalize(candidate['term'] as String) != _normalize(term),
            )
            .map((candidate) => (candidate['term'] as String).trim())
            .toSet()
            .toList()
          ..shuffle(random);
    final options = <String>[
      term,
      ...distractors.take(min(3, distractors.length)),
    ]..shuffle(random);
    return QuizQuestion(
      prompt: definition,
      answer: term,
      options: List.unmodifiable(options),
    );
  }

  static List<Map<String, Object?>> _uniqueTerms(
    List<Map<String, Object?>> words,
  ) {
    final seen = <String>{};
    return words.where((word) {
      final term = word['term'];
      final definition = word['definition'];
      if (term is! String || term.trim().isEmpty) return false;
      if (definition is! String || definition.trim().isEmpty) return false;
      return seen.add(_normalize(term));
    }).toList();
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
