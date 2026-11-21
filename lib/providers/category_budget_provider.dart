import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/services/category_budget_repository.dart';
import '../models/category_budget.dart';
import 'transaction_provider.dart';

final categoryBudgetRepositoryProvider = FutureProvider<CategoryBudgetRepository>((ref) async {
  return CategoryBudgetRepository(await AppDatabase.instance.database);
});

final categoryBudgetLimitsProvider = FutureProvider<Map<String, double>>((ref) async {
  return (await ref.watch(categoryBudgetRepositoryProvider.future)).load();
});

final categoryBudgetUsageProvider = Provider.family<AsyncValue<List<CategoryBudgetUsage>>, DateTime>((ref, month) {
  final limits = ref.watch(categoryBudgetLimitsProvider);
  final transactions = ref.watch(transactionProvider);
  if (limits.hasError) return AsyncValue.error(limits.error!, limits.stackTrace!);
  if (transactions.hasError) return AsyncValue.error(transactions.error!, transactions.stackTrace!);
  if (limits.isLoading || transactions.isLoading) return const AsyncValue.loading();
  return AsyncValue.data([
    for (final entry in limits.requireValue.entries)
      CategoryBudgetUsage.calculate(entry.key, entry.value, transactions.requireValue, month),
  ]);
});
