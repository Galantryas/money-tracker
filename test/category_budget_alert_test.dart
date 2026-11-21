import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/category_budget.dart';
import 'package:money_tracker/providers/category_budget_provider.dart';
import 'package:money_tracker/views/budgets/category_budget_alerts.dart';

void main() {
  testWidgets('alerts name near and exceeded categories without exposing amounts', (tester) async {
    final month = DateTime(2026, 11);
    await tester.pumpWidget(ProviderScope(overrides: [
      categoryBudgetUsageProvider(month).overrideWith((ref) => const AsyncValue.data([
        CategoryBudgetUsage('Tempat Tinggal', 100, 110),
        CategoryBudgetUsage('Layanan', 100, 85),
        CategoryBudgetUsage('Belanja', 100, 10),
      ])),
    ], child: MaterialApp(home: Scaffold(body: CategoryBudgetAlerts(month: month)))));
    expect(find.textContaining('Tempat Tinggal: batas tercapai'), findsOneWidget);
    expect(find.textContaining('Layanan: mendekati batas'), findsOneWidget);
    expect(find.textContaining('Belanja:'), findsNothing);
    expect(find.textContaining('Rp'), findsNothing);
    expect(find.text('Lihat anggaran'), findsOneWidget);
  });
}
