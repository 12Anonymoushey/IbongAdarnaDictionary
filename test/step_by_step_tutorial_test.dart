import 'package:dictionary/widgets/step_by_step_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tutorial coach marks advance, go back, and finish', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showStepByStepTutorial(
                context: context,
                title: 'Adarna Mode tutorial',
                steps: const [
                  TutorialStep(
                    title: 'Open Adarna Mode',
                    description: 'Tap the bird logo.',
                    icon: Icons.flutter_dash,
                  ),
                  TutorialStep(
                    title: 'Use hearts',
                    description: 'Searches use hearts.',
                    icon: Icons.favorite,
                  ),
                ],
              ),
              child: const Text('Start tutorial'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Open Adarna Mode'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Use hearts'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open Adarna Mode'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Open Adarna Mode'), findsNothing);
  });
}
