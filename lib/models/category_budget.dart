import 'transaction_model.dart';

class CategoryBudgetUsage {
  final String category;
  final double limit;
  final double spent;

  const CategoryBudgetUsage(this.category, this.limit, this.spent);

  double get remaining => limit - spent;
  double get fraction => limit > 0 ? spent / limit : 0;
  bool get isNearLimit => fraction >= 0.8 && fraction < 1;
  bool get isOverLimit => fraction >= 1;

  static CategoryBudgetUsage calculate(String category, double limit,
      List<TransactionModel> transactions, DateTime month) {
    final spent = transactions.where((tx) => tx.isExpense && tx.category == category &&
        tx.date.year == month.year && tx.date.month == month.month)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    return CategoryBudgetUsage(category, limit, spent);
  }
}
