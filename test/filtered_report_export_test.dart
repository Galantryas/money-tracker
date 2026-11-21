import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/transaction_export_provider.dart';
import 'package:money_tracker/views/reports/date_range_report_screen.dart';
import 'support/finance_fixtures.dart';

void main() {
  testWidgets('report export shares only the selected expense period', (tester) async {
    await initializeDateFormatting('id_ID');
    FlutterSecureStorage.setMockInitialValues({'is_balance_visible': 'true'});
    List<TransactionModel>? exported;
    await tester.pumpWidget(ProviderScope(overrides: [
      ...financeOverrides(),
      transactionExporterProvider.overrideWithValue((transactions) async { exported = transactions; }),
    ], child: const MaterialApp(home: DateRangeReportScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bagikan laporan CSV'));
    await tester.pumpAndSettle();
    expect(exported?.map((tx) => tx.id), ['expense']);
    await tester.ensureVisible(find.text('Pemasukan (1)'));
    await tester.tap(find.text('Pemasukan (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bagikan laporan CSV'));
    await tester.pumpAndSettle();
    expect(exported?.map((tx) => tx.id), ['income']);
    expect(tester.takeException(), isNull);
  });
}
