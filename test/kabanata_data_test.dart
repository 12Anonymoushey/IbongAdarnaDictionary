import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary/features/activities/quiz_builder.dart';
import 'package:dictionary/features/kabanata/kabanata_data.dart';
import 'package:dictionary/features/kabanata/mga_kabanata_screen.dart';

void main() {
  test('all 46 kabanata have titles and Filipino descriptions', () {
    expect(kabanataList, hasLength(46));
    for (var index = 0; index < kabanataList.length; index++) {
      final kabanata = kabanataList[index];
      expect(kabanata.number, index + 1);
      expect(kabanata.title, isNotEmpty);
      expect(kabanata.description, isNotEmpty);
      expect(kabanata.imagePath, startsWith('assets/images/'));
    }
    expect(
      kabanataByNumber(46)?.title,
      'Ang Hari at Reyna ng Reyno Delos Cristales',
    );
    expect(kabanataByNumber(0), isNull);
  });

  testWidgets('Mga Kabanata screen shows the two-column chapter cards', (
    tester,
  ) async {
    final navigatorObserver = _TestNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [navigatorObserver],
        home: const Scaffold(body: MgaKabanataScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mga Kabanata'), findsOneWidget);
    expect(find.text('KABANATA 1'), findsOneWidget);
    expect(find.text('Ang Berbanya'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    final initialPushCount = navigatorObserver.pushCount;
    final card = tester.widget<InkWell>(find.byType(InkWell).first);
    expect(card.onTap, isNotNull);
    await tester.tap(find.byType(InkWell).first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(navigatorObserver.pushCount, initialPushCount + 1);
    expect(find.byType(KabanataWordsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('chapter quiz words can generate questions from that chapter only', () {
    final dictionary = [
      {'term': 'Aatungal', 'definition': 'Iiyak nang malakas.', 'kabanata': 15},
      {'term': 'Dayap', 'definition': 'Isang uri ng prutas.', 'kabanata': 15},
      {'term': 'Datay', 'definition': 'Lumapit.', 'kabanata': 1},
    ];
    final chapterWords = QuizBuilder.wordsForKabanata(dictionary, 15);

    expect(chapterWords.map((word) => word['term']), ['Aatungal', 'Dayap']);
    final questions = QuizBuilder.build(
      mode: QuizMode.identification,
      words: chapterWords,
      dictionaryWords: dictionary,
    );
    expect(questions.map((question) => question.answer), ['Aatungal', 'Dayap']);
  });
}

class _TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}
