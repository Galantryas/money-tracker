import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/views/ai/ai_consent_dialog.dart';

void main() {
  testWidgets('explains shared financial data and allows cancellation', (tester) async {
    bool? decision;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return TextButton(
        onPressed: () async => decision = await showAiConsentDialog(context),
        child: const Text('Open'),
      );
    })));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('catatan'), findsOneWidget);
    expect(find.textContaining('Gemini'), findsWidgets);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(decision, isFalse);
  });
}
