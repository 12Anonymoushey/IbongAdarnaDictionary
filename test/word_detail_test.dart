import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary/features/search/word_detail_screen.dart';

void main() {
  testWidgets('word detail displays dictionary metadata and chapter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WordDetailScreen(
          word: {
            'id': 1,
            'term': 'Aatungal',
            'definition': 'Iiyak nang malakas.',
            'part_of_speech': 'Pandiwa',
            'synonyms': 'Iiyak, Hahagulgol',
            'antonyms': 'Tatawa',
            'sample_sentence': 'Aatungal sana ang prinsipe.',
            'kabanata': 15,
            'is_saved': 0,
          },
        ),
      ),
    );

    expect(find.text('Aatungal'), findsWidgets);
    expect(find.text('Bigkas'), findsOneWidget);
    expect(find.text('Kahulugan'), findsOneWidget);
    expect(find.text('Pandiwa'), findsOneWidget);
    expect(find.text('Iiyak, Hahagulgol'), findsOneWidget);
    expect(find.text('Tatawa'), findsOneWidget);
    expect(find.text('Aatungal sana ang prinsipe.'), findsOneWidget);
    expect(
      find.text('Kabanata 15: Ang Muling Paglisan ni Don Juan'),
      findsOneWidget,
    );
    expect(find.byTooltip('Share word'), findsOneWidget);
    expect(find.byTooltip('Listen to pronunciation'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
