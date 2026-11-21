import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/services/transaction_csv_service.dart';
import 'package:money_tracker/models/transaction_model.dart';

void main() {
  test('escapes quotes, commas and newlines in transaction fields', () {
    final tx = TransactionModel(
      id: 'tx1', pocketId: 'p1', type: 'expense', amount: 100,
      category: 'Food', merchant: 'Shop "A"', note: 'first,\nsecond',
      date: DateTime(2024, 1, 2), createdAt: DateTime(2024, 1, 2),
    );
    final csv = TransactionCsvService.encode([tx]);
    expect(csv, contains('"Shop ""A"""'));
    expect(csv, contains('"first,\nsecond"'));
    expect(csv, contains('"p1"'));
  });
}
