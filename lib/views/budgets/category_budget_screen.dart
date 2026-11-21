import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/balance_privacy_provider.dart';
import '../../providers/category_budget_provider.dart';
import '../../providers/transaction_provider.dart';
import 'category_budget_dialog.dart';

class CategoryBudgetScreen extends ConsumerWidget {
  final DateTime month;
  const CategoryBudgetScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final usages = ref.watch(categoryBudgetUsageProvider(month));
    final visible = ref.watch(balancePrivacyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Anggaran kategori')),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(categoriesProvider), child: const Text('Muat ulang kategori'),
        )),
        data: (rows) => usages.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Anggaran tidak dapat dimuat.'),
            TextButton(onPressed: () {
              ref.invalidate(categoryBudgetLimitsProvider);
              ref.read(transactionProvider.notifier).loadTransactions();
            }, child: const Text('Coba lagi')),
          ])),
          data: (items) {
            final names = <String>{
              for (final row in rows.where((row) => row['type'] == 'expense')) row['name'] as String,
              for (final item in items) item.category,
            }.toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(DateFormatter.formatMonthYear(month), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Batas berlaku setiap bulan untuk seluruh kantong. Peringatan tampil di aplikasi saat pemakaian mencapai 80% dan 100%.'),
                const SizedBox(height: 16),
                if (names.isEmpty) const Text('Belum ada kategori pengeluaran.'),
                for (final name in names) Builder(builder: (context) {
                  final matches = items.where((item) => item.category == name);
                  final usage = matches.isEmpty ? null : matches.first;
                  final status = usage == null ? 'Belum ada batas'
                      : usage.isOverLimit ? 'Batas tercapai'
                      : usage.isNearLimit ? 'Mendekati batas' : 'Dalam anggaran';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    title: Text(name),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(status),
                      if (usage != null) ...[
                        Text('Terpakai ${CurrencyFormatter.privateAmount(usage.spent, isVisible: visible)} dari ${CurrencyFormatter.privateAmount(usage.limit, isVisible: visible)}'),
                        Text('${usage.remaining < 0 ? "Melebihi" : "Sisa"}: ${CurrencyFormatter.privateAmount(usage.remaining.abs(), isVisible: visible)}'),
                      ],
                    ]),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final result = await showCategoryBudgetDialog(context, name, usage?.limit);
                      if (result == null || !context.mounted) return;
                      try {
                        final repository = await ref.read(categoryBudgetRepositoryProvider.future);
                        if (result.remove) {
                          await repository.removeLimit(name);
                        } else {
                          await repository.setLimit(name, CurrencyFormatter.parse(result.amount!));
                        }
                        ref.invalidate(categoryBudgetLimitsProvider);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Anggaran gagal disimpan. Silakan coba lagi.')),
                          );
                        }
                      }
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
