import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/core/theme/app_theme.dart';
import 'package:money_tracker/providers/category_budget_provider.dart';
import 'package:money_tracker/views/budgets/category_budget_screen.dart';
import 'package:money_tracker/views/reports/date_range_report_screen.dart';
import 'package:money_tracker/views/stats/stats_screen.dart';
import 'package:money_tracker/views/transactions/transaction_history_screen.dart';
import 'support/finance_fixtures.dart';

void main() {
  final screens = <String, Widget Function()>{
    'budgets': () => CategoryBudgetScreen(
        month: DateTime(DateTime.now().year, DateTime.now().month)),
    'report': () => const DateRangeReportScreen(),
    'statistics': () => const StatsScreen(),
    'history': () => const TransactionHistoryScreen(),
  };
  for (final dark in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets(
          '${entry.key} at 320px and 200% text, ${dark ? "dark" : "light"}',
          (tester) async {
        await initializeDateFormatting('id_ID');
        FlutterSecureStorage.setMockInitialValues(
            {'is_balance_visible': 'true'});
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              ...financeOverrides(),
              categoryBudgetLimitsProvider
                  .overrideWith((ref) async => {'Tempat Tinggal': 1000000}),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 2),
                child: child!,
              ),
              home: entry.value(),
            )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
