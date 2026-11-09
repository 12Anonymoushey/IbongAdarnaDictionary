import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dictionary/widgets/dictionary_bar.dart';

void main() {
  testWidgets('Adarna Mode sheet fits a short window without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: DictionaryBar(), body: SizedBox.expand()),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Open Adarna Mode'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Adarna Mode'), findsNWidgets(2));
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
