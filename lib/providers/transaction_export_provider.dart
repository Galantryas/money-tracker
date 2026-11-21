import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/transaction_csv_service.dart';
import '../models/transaction_model.dart';

final transactionExporterProvider = Provider<Future<void> Function(List<TransactionModel>)>((ref) {
  return TransactionCsvService.share;
});
