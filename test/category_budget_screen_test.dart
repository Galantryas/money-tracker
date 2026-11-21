import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/core/services/category_budget_repository.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/category_budget_provider.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/views/budgets/category_budget_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class BudgetTransactions extends TransactionNotifier {
  BudgetTransactions(super.ref) {
    state = AsyncValue.data([TransactionModel(id: 't', pocketId: 'p', type: 'expense',
        amount: 85, category: 'Tempat Tinggal', note: '', merchant: '',
        date: DateTime(2026, 11, 2), createdAt: DateTime(2026, 11, 2))]);
  }
  @override
  Future<void> loadTransactions() async {}
}

class MemoryBudgetRepository implements CategoryBudgetRepository {
  final limits = <String, double>{};
  @override
  Database get database => throw UnsupportedError('This test uses memory storage.');
  @override
  Future<Map<String, double>> load() async => Map.of(limits);
  @override
  Future<void> setLimit(String category, double limit) async => limits[category] = limit;
  @override
  Future<void> removeLimit(String category) async => limits.remove(category);
}

void main() {
  testWidgets('saves, warns near limit, and removes a category budget', (tester) async {
    await initializeDateFormatting('id_ID');
    FlutterSecureStorage.setMockInitialValues({'is_balance_visible': 'true'});
    final repo = MemoryBudgetRepository();
    await tester.pumpWidget(ProviderScope(overrides: [
      categoryBudgetRepositoryProvider.overrideWith((ref) async => repo),
      categoriesProvider.overrideWith((ref) async => [{'name': 'Tempat Tinggal', 'type': 'expense'}]),
      transactionProvider.overrideWith((ref) => BudgetTransactions(ref)),
    ], child: MaterialApp(home: CategoryBudgetScreen(month: DateTime(2026, 11)))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tempat Tinggal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '100');
    await tester.tap(find.text('Simpan batas'));
    await tester.pumpAndSettle();
    expect(await repo.load(), {'Tempat Tinggal': 100.0});
    expect(find.textContaining('Mendekati batas'), findsOneWidget);
    await tester.tap(find.text('Tempat Tinggal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Simpan batas'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan batas lebih dari nol.'), findsOneWidget);
    expect(await repo.load(), {'Tempat Tinggal': 100.0});
    await tester.tap(find.text('Hapus batas'));
    await tester.pumpAndSettle();
    expect(await repo.load(), isEmpty);
    expect(find.text('Belum ada batas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
