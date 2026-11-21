import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/models/pocket.dart';

void main() {
  test('can clear an existing budget without changing other fields', () {
    final pocket = Pocket(
      id: 'p1', name: 'Cash', iconName: 'wallet', colorValue: 1,
      initialBalance: 100, budgetLimit: 50, createdAt: DateTime(2024),
    );
    final updated = pocket.copyWith(clearBudgetLimit: true);
    expect(updated.budgetLimit, isNull);
    expect(updated.initialBalance, 100);
    expect(updated.id, 'p1');
  });
}
