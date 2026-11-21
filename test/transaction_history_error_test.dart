import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/views/transactions/transaction_history_screen.dart';

class FailedTransactions extends TransactionNotifier {
  FailedTransactions(super.ref) {
    state = AsyncValue.error(Exception('database'), StackTrace.empty);
  }

  @override
  Future<void> loadTransactions() async {}
}

void main() {
  testWidgets('history offers a retry when transactions fail to load', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [transactionProvider.overrideWith((ref) => FailedTransactions(ref))],
      child: const MaterialApp(home: TransactionHistoryScreen()),
    ));
    expect(find.text('Riwayat transaksi tidak dapat dimuat.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
