import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary/main.dart';

void main() {
  testWidgets('dictionary app displays its startup screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const IbongAdarnaApp());

    expect(find.text('DICTIONARY'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
