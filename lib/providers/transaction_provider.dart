import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../models/transaction_model.dart';
import 'pocket_provider.dart';
import '../core/utils/category_order.dart';

class TransactionNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final Ref _ref;

  TransactionNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final db = await AppDatabase.instance.database;
      final maps = await db.query('transactions', orderBy: 'date DESC, created_at DESC');
      final list = maps.map((e) => TransactionModel.fromMap(e)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await AppDatabase.instance.database;
    await db.insert('transactions', transaction.toMap());
    await loadTransactions();
    // Sinkronisasi saldo kantong
    await _ref.read(pocketProvider.notifier).loadPockets();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    await loadTransactions();
    await _ref.read(pocketProvider.notifier).loadPockets();
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    await loadTransactions();
    await _ref.read(pocketProvider.notifier).loadPockets();
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  return TransactionNotifier(ref);
});

// Category model & provider for category dropdowns
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await AppDatabase.instance.database;
  final list = await AppDatabase.instance.loadCategories(db);
  return orderCategories(list);
});

// Provider untuk Total Pengeluaran & Pemasukan Bulan Berjalan
class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double netCashflow;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
  });
}

final currentMonthSummaryProvider = Provider<MonthlySummary>((ref) {
  final txAsync = ref.watch(transactionProvider);
  return txAsync.maybeWhen(
    data: (transactions) {
      final now = DateTime.now();
      double income = 0;
      double expense = 0;

      for (var tx in transactions) {
        if (tx.date.year == now.year && tx.date.month == now.month) {
          if (tx.isIncome) {
            income += tx.amount;
          } else if (tx.isExpense) {
            expense += tx.amount;
          }
        }
      }

      return MonthlySummary(
        totalIncome: income,
        totalExpense: expense,
        netCashflow: income - expense,
      );
    },
    orElse: () => MonthlySummary(totalIncome: 0, totalExpense: 0, netCashflow: 0),
  );
});

// Provider untuk pengeluaran per kategori bulan ini (fl_chart)
class CategorySpending {
  final String categoryName;
  final double totalAmount;
  final double percentage;

  CategorySpending({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
  });
}

final categorySpendingProvider = Provider.family<List<CategorySpending>, DateTime>((ref, selectedMonth) {
  final txAsync = ref.watch(transactionProvider);
  return txAsync.maybeWhen(
    data: (transactions) {
      final Map<String, double> grouped = {};
      double grandTotal = 0;

      for (var tx in transactions) {
        if (tx.isExpense &&
            tx.date.year == selectedMonth.year &&
            tx.date.month == selectedMonth.month) {
          grouped[tx.category] = (grouped[tx.category] ?? 0) + tx.amount;
          grandTotal += tx.amount;
        }
      }

      if (grandTotal == 0) return [];

      final list = grouped.entries.map((entry) {
        return CategorySpending(
          categoryName: entry.key,
          totalAmount: entry.value,
          percentage: (entry.value / grandTotal) * 100,
        );
      }).toList();

      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return list;
    },
    orElse: () => [],
  );
});
