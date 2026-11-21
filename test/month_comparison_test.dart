import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/month_comparison.dart';
import 'package:money_tracker/models/transaction_model.dart';

void main() {
  TransactionModel tx(String type, double amount, DateTime date) => TransactionModel(
    id: '$type$amount', pocketId: 'p', type: type, amount: amount,
    category: '', note: '', merchant: '', date: date, createdAt: date,
  );

  test('compares selected month with previous calendar month excluding transfers', () {
    final result = compareMonths([
      tx('expense', 100, DateTime(2024, 1, 1)),
      tx('expense', 80, DateTime(2023, 12, 31)),
      tx('income', 200, DateTime(2024, 1, 4)),
      tx('income', 150, DateTime(2023, 12, 4)),
      tx('transfer', 999, DateTime(2024, 1, 4)),
    ], DateTime(2024, 1));
    expect(result.incomeDifference, 50);
    expect(result.expenseDifference, 20);
  });
}
