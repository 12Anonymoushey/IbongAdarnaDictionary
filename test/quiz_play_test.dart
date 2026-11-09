import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary/features/activities/quiz_builder.dart';
import 'package:dictionary/features/activities/quiz_screens.dart';

void main() {
  const question = QuizQuestion(
    prompt: 'A magical bird.',
    answer: 'Adarna',
    options: ['Adarna', 'Harana'],
  );
  const freestyleQuestion = QuizQuestion(
    prompt: 'A magical bird.',
    answer: 'Adarna',
  );
  const flashcardQuestion = QuizQuestion(
    prompt: 'Adarna',
    answer: 'A magical bird.',
  );

  testWidgets('multiple-choice quiz checks the selected answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuizPlayScreen(
          name: 'Multiple Choice',
          mode: QuizMode.multipleChoice,
          source: QuizWordSource.freestyle,
          questions: [question],
        ),
      ),
    );

    await tester.tap(find.text('Adarna'));
    await tester.pump();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    await tester.tap(find.text('Check answer'));
    await tester.pump();

    expect(find.text('Correct!'), findsOneWidget);
    expect(find.text('Finish quiz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('identification quiz accepts case-insensitive answers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuizPlayScreen(
          name: 'Identification',
          mode: QuizMode.identification,
          source: QuizWordSource.chooseWords,
          questions: [freestyleQuestion],
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'adarna');
    await tester.tap(find.text('Check answer'));
    await tester.pump();

    expect(find.text('Correct!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('flashcards reveal, score, and advance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuizPlayScreen(
          name: 'Flashcards',
          mode: QuizMode.flashcards,
          source: QuizWordSource.randomWords,
          questions: [flashcardQuestion],
        ),
      ),
    );

    await tester.tap(find.text('Reveal answer'));
    await tester.pump();
    expect(find.text('A magical bird.'), findsOneWidget);

    await tester.tap(find.text('I knew it'));
    await tester.pump();
    expect(find.text('Marked as known.'), findsOneWidget);
    expect(find.text('Finish quiz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('retakes are reset and recorded for every quiz type', (
    tester,
  ) async {
    for (final mode in QuizMode.values) {
      final savedScores = <int>[];
      final questions = switch (mode) {
        QuizMode.multipleChoice => [question],
        QuizMode.identification => [freestyleQuestion],
        QuizMode.flashcards => [flashcardQuestion],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: QuizPlayScreen(
            name: mode.name,
            mode: mode,
            source: QuizWordSource.freestyle,
            questions: questions,
            onSaveResult: (score, maxScore, details) async {
              savedScores.add(score);
            },
          ),
        ),
      );

      Future<void> finishAttempt() async {
        switch (mode) {
          case QuizMode.multipleChoice:
            await tester.tap(find.text('Adarna'));
            await tester.pump();
            await tester.tap(find.text('Check answer'));
          case QuizMode.identification:
            await tester.enterText(find.byType(TextField), 'Adarna');
            await tester.tap(find.text('Check answer'));
          case QuizMode.flashcards:
            await tester.tap(find.text('Reveal answer'));
            await tester.pump();
            await tester.tap(find.text('I knew it'));
            await tester.pump();
        }
        await tester.pump();
        await tester.tap(find.text('Finish quiz'));
        await tester.pumpAndSettle();
      }

      await finishAttempt();
      expect(savedScores, hasLength(1));
      expect(find.text('Retake quiz'), findsOneWidget);

      await tester.tap(find.text('Retake quiz'));
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);

      await finishAttempt();
      expect(savedScores, hasLength(2));
      expect(
        find.textContaining('Each attempt is recorded separately.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
