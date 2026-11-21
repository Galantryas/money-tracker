import '../../models/transaction_model.dart';

class MonthComparison {
  final double incomeDifference;
  final double expenseDifference;
  const MonthComparison(this.incomeDifference, this.expenseDifference);
}

MonthComparison compareMonths(List<TransactionModel> transactions, DateTime month) {
  final selected = DateTime(month.year, month.month);
  final previous = DateTime(month.year, month.month - 1);
  var incomeDifference = 0.0;
  var expenseDifference = 0.0;
  for (final tx in transactions) {
    final date = DateTime(tx.date.year, tx.date.month);
    final factor = date == selected ? 1 : (date == previous ? -1 : 0);
    if (tx.isIncome) incomeDifference += tx.amount * factor;
    if (tx.isExpense) expenseDifference += tx.amount * factor;
  }
  return MonthComparison(incomeDifference, expenseDifference);
}
