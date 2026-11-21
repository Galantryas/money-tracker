import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transaction_model.dart';

class TransactionCsvService {
  static String _field(Object? value) =>
      '"${(value?.toString() ?? '').replaceAll('"', '""')}"';

  static String encode(List<TransactionModel> transactions) {
    final buffer = StringBuffer('ID,Kantong ID,Kantong Tujuan ID,Tanggal,Tipe,Kategori,Merchant,Catatan,Nominal\r\n');
    for (final tx in transactions) {
      buffer.writeln([
        tx.id, tx.pocketId, tx.targetPocketId, tx.date.toIso8601String(),
        tx.type, tx.category, tx.merchant, tx.note, tx.amount,
      ].map(_field).join(','));
    }
    return buffer.toString();
  }

  static Future<void> share(List<TransactionModel> transactions) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/money_tracker_transactions.csv');
    await file.writeAsString(encode(transactions), flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')],
        subject: 'Riwayat transaksi Money Tracker');
  }
}
