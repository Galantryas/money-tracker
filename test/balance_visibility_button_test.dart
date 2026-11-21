import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/views/widgets/balance_visibility_button.dart';

void main() {
  testWidgets('visibility control has an accessible label and invokes its action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: BalanceVisibilityButton(isVisible: true, onPressed: () => taps++),
    )));
    expect(find.byTooltip('Sembunyikan saldo'), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton)).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
  });
}
