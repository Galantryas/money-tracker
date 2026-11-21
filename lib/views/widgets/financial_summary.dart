import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class FinancialSummary extends StatelessWidget {
  final double income;
  final double expense;
  final bool isVisible;
  final bool showNet;
  const FinancialSummary({super.key, required this.income, required this.expense,
    required this.isVisible, this.showNet = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget metric(String label, double amount) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(CurrencyFormatter.privateAmount(amount, isVisible: isVisible),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ]),
    );
    final metrics = [metric('Pemasukan', income), metric('Pengeluaran', expense)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, constraints) =>
          constraints.maxWidth < 400 || MediaQuery.textScaleFactorOf(context) > 1.3
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: metrics)
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final item in metrics) Expanded(child: item),
                ])),
        if (showNet) ...[
          const Divider(),
          metric('Selisih bersih', income - expense),
        ],
      ]),
    );
  }
}
