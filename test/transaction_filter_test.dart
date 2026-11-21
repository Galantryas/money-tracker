import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/transaction_filter.dart';
import 'package:money_tracker/models/transaction_model.dart';

void main() {
  TransactionModel tx(String id, String category, DateTime date) => TransactionModel(
        id: id, pocketId: 'p', type: 'expense', amount: 10,
        category: category, merchant: '', note: '', date: date, createdAt: date,
      );

  test('filters by category and includes the entire final day', () {
    final entries = [
      tx('1', 'Food', DateTime(2024, 1, 1)),
      tx('2', 'Food', DateTime(2024, 1, 31, 23, 59)),
      tx('3', 'Food', DateTime(2024, 2, 1)),
      tx('4', 'Travel', DateTime(2024, 1, 15)),
    ];
    final result = filterTransactions(entries, category: 'Food',
        start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 31));
    expect(result.map((t) => t.id), ['1', '2']);
  });

  test('report selection applies pocket, type and date together', () {
    final entries = [
      tx('1', 'Food', DateTime(2024, 1, 1)),
      tx('2', 'Food', DateTime(2024, 2, 1)),
      TransactionModel(id: 'income', pocketId: 'p', type: 'income', amount: 20,
        category: 'Salary', note: '', merchant: '', date: DateTime(2024, 1, 1), createdAt: DateTime(2024)),
      TransactionModel(id: 'other', pocketId: 'q', type: 'expense', amount: 20,
        category: 'Food', note: '', merchant: '', date: DateTime(2024, 1, 1), createdAt: DateTime(2024)),
    ];
    expect(filterTransactions(entries, pocketId: 'p', type: 'expense',
        start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 31)).map((tx) => tx.id), ['1']);
  });
}
