import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/store/widgets/sales_editor_sheet.dart';

void main() {
  testWidgets('disposing a dismissed sales editor does not reuse controllers', (
    tester,
  ) async {
    await tester.pumpWidget(const _SalesEditorHarness());

    await tester.tap(find.text('売上入力を開く'));
    await tester.pumpAndSettle();
    expect(find.byType(SalesEditorSheet), findsOneWidget);

    Navigator.of(tester.element(find.byType(SalesEditorSheet))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(SalesEditorSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales editor captures values and prevents duplicate saves', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();
    var saveCount = 0;
    double? savedPrice;
    String? savedMenu;
    DateTime? savedDate;

    await tester.pumpWidget(
      _SalesEditorHarness(
        onSave: ({required price, required menu, required date}) {
          saveCount += 1;
          savedPrice = price;
          savedMenu = menu;
          savedDate = date;
          return saveCompleter.future;
        },
      ),
    );

    await tester.tap(find.text('売上入力を開く'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '金額'),
      '12000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'メニュー'),
      'カット',
    );

    await tester.tap(find.text('保存'));
    await tester.tap(find.text('保存'), warnIfMissed: false);
    await tester.pump();

    expect(saveCount, 1);
    expect(savedPrice, 12000);
    expect(savedMenu, 'カット');
    expect(savedDate, DateTime(2026, 6, 9));

    saveCompleter.complete();
    await tester.pumpAndSettle();

    expect(find.byType(SalesEditorSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _SalesEditorHarness extends StatelessWidget {
  const _SalesEditorHarness({this.onSave});

  final SaveSale? onSave;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SalesEditorSheet(
                    initialDate: DateTime(2026, 6, 9),
                    onSave: onSave ??
                        ({required price, required menu, required date}) async {},
                  ),
                );
              },
              child: const Text('売上入力を開く'),
            ),
          ),
        ),
      ),
    );
  }
}
