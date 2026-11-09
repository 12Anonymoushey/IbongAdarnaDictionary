import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary/features/activities/quiz_builder.dart';

void main() {
  const dictionary = [
    {'id': 1, 'term': 'Adarna', 'definition': 'A magical bird.'},
    {'id': 2, 'term': 'Harana', 'definition': 'A traditional serenade.'},
    {'id': 3, 'term': 'Bayanihan', 'definition': 'Community cooperation.'},
    {'id': 4, 'term': 'Kundiman', 'definition': 'A traditional love song.'},
  ];

  test('multiple choice contains the right answer and unique choices', () {
    final questions = QuizBuilder.build(
      mode: QuizMode.multipleChoice,
      words: [dictionary.first],
      dictionaryWords: dictionary,
      random: Random(4),
    );

    expect(questions, hasLength(1));
    expect(questions.single.answer, 'Adarna');
    expect(questions.single.prompt, 'A magical bird.');
    expect(questions.single.options, contains('Adarna'));
    expect(questions.single.options.toSet(), hasLength(4));
  });

  test(
    'identification prompts with the definition and checks answer safely',
    () {
      final question = QuizBuilder.build(
        mode: QuizMode.identification,
        words: [dictionary.first],
      ).single;

      expect(question.prompt, 'A magical bird.');
      expect(question.answer, 'Adarna');
      expect(QuizBuilder.answerMatches('  adarna  ', question.answer), isTrue);
      expect(QuizBuilder.answerMatches('wrong', question.answer), isFalse);
    },
  );

  test('flashcards reveal the definition for the chosen word', () {
    final question = QuizBuilder.build(
      mode: QuizMode.flashcards,
      words: [dictionary.first],
    ).single;

    expect(question.prompt, 'Adarna');
    expect(question.answer, 'A magical bird.');
  });

  test('saved quiz questions round-trip with all answer options', () {
    const question = QuizQuestion(
      prompt: 'A magical bird.',
      answer: 'Adarna',
      options: ['Adarna', 'Harana'],
    );

    expect(
      QuizQuestion.fromJson(question.toJson()).toJson(),
      question.toJson(),
    );
  });

  test('random word selection returns the requested unique number', () {
    final selected = QuizBuilder.randomWords(dictionary, 3, random: Random(11));

    expect(selected, hasLength(3));
    expect(selected.map((word) => word['id']).toSet(), hasLength(3));
  });

  test('multiple choice rejects a one-word dictionary', () {
    expect(
      () => QuizBuilder.build(
        mode: QuizMode.multipleChoice,
        words: [dictionary.first],
        dictionaryWords: [dictionary.first],
      ),
      throwsArgumentError,
    );
  });
}
