import '../../models/transaction_model.dart';

List<TransactionModel> filterTransactions(
  List<TransactionModel> transactions, {
  String? category,
  String? pocketId,
  String? type,
  DateTime? start,
  DateTime? end,
}) {
  final startDay = start == null ? null : DateTime(start.year, start.month, start.day);
  final endExclusive = end == null ? null : DateTime(end.year, end.month, end.day + 1);
  return transactions.where((tx) {
    if (type != null && tx.type != type) return false;
    if (pocketId != null && tx.pocketId != pocketId && tx.targetPocketId != pocketId) return false;
    if (category != null && tx.category != category) return false;
    if (startDay != null && tx.date.isBefore(startDay)) return false;
    if (endExclusive != null && !tx.date.isBefore(endExclusive)) return false;
    return true;
  }).toList();
}
