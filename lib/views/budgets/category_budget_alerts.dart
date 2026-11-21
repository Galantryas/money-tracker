import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/category_budget_provider.dart';
import 'category_budget_screen.dart';

class CategoryBudgetAlerts extends ConsumerWidget {
  final DateTime month;
  const CategoryBudgetAlerts({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(categoryBudgetUsageProvider(month)).maybeWhen(
      data: (usages) {
        final alerts = usages.where((usage) => usage.isNearLimit || usage.isOverLimit).toList();
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Perhatian anggaran', style: Theme.of(context).textTheme.titleMedium),
            for (final alert in alerts)
              Text('${alert.category}: ${alert.isOverLimit ? "batas tercapai" : "mendekati batas"}'),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CategoryBudgetScreen(month: month),
              )),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Lihat anggaran'),
            ),
          ]),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
