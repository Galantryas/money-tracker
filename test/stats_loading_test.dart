import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/views/stats/stats_screen.dart';

class LoadingTransactions extends TransactionNotifier {
  LoadingTransactions(super.ref);
  @override
  Future<void> loadTransactions() async {}
}

void main() {
  testWidgets('loading statistics is not presented as no expenses', (tester) async {
    await initializeDateFormatting('id_ID');
    await tester.pumpWidget(ProviderScope(
      overrides: [transactionProvider.overrideWith((ref) => LoadingTransactions(ref))],
      child: const MaterialApp(home: StatsScreen()),
    ));
    expect(find.text('Memuat statistik...'), findsOneWidget);
    expect(find.text('Tidak ada pengeluaran tercatat di bulan ini'), findsNothing);
  });
}
