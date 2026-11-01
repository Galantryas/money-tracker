import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../models/pocket.dart';
import '../models/transaction_model.dart';

class PocketWithBalance {
  final Pocket pocket;
  final double currentBalance;
  final double spentThisMonth;
  final double incomeThisMonth;

  PocketWithBalance({
    required this.pocket,
    required this.currentBalance,
    required this.spentThisMonth,
    required this.incomeThisMonth,
  });

  double? get budgetUsagePercentage {
    if (pocket.budgetLimit == null || pocket.budgetLimit! <= 0) return null;
    return spentThisMonth / pocket.budgetLimit!;
  }
}

class PocketNotifier extends StateNotifier<AsyncValue<List<PocketWithBalance>>> {
  PocketNotifier() : super(const AsyncValue.loading()) {
    loadPockets();
  }

  Future<void> loadPockets() async {
    try {
      final db = await AppDatabase.instance.database;
      final pocketMaps = await db.query('pockets', orderBy: 'created_at ASC');
      final txMaps = await db.query('transactions');

      final pockets = pocketMaps.map((e) => Pocket.fromMap(e)).toList();
      final transactions = txMaps.map((e) => TransactionModel.fromMap(e)).toList();

      final now = DateTime.now();

      final result = pockets.map((pocket) {
        double balance = pocket.initialBalance;
        double spentMonth = 0;
        double incomeMonth = 0;

        for (var tx in transactions) {
          final isCurrentMonth = tx.date.year == now.year && tx.date.month == now.month;

          if (tx.isExpense && tx.pocketId == pocket.id) {
            balance -= tx.amount;
            if (isCurrentMonth) spentMonth += tx.amount;
          } else if (tx.isIncome && tx.pocketId == pocket.id) {
            balance += tx.amount;
            if (isCurrentMonth) incomeMonth += tx.amount;
          } else if (tx.isTransfer) {
            if (tx.pocketId == pocket.id) {
              // Uang keluar dari pocket ini
              balance -= tx.amount;
            } else if (tx.targetPocketId == pocket.id) {
              // Uang masuk ke pocket ini
              balance += tx.amount;
            }
          }
        }

        return PocketWithBalance(
          pocket: pocket,
          currentBalance: balance,
          spentThisMonth: spentMonth,
          incomeThisMonth: incomeMonth,
        );
      }).toList();

      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPocket(Pocket pocket) async {
    final db = await AppDatabase.instance.database;
    await db.insert('pockets', pocket.toMap());
    await loadPockets();
  }

  Future<void> updatePocket(Pocket pocket) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'pockets',
      pocket.toMap(),
      where: 'id = ?',
      whereArgs: [pocket.id],
    );
    await loadPockets();
  }

  Future<void> deletePocket(String pocketId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'pockets',
      where: 'id = ?',
      whereArgs: [pocketId],
    );
    // Transaksi terkait juga terhapus berkat cascade atau hapus manual
    await db.delete(
      'transactions',
      where: 'pocket_id = ? OR target_pocket_id = ?',
      whereArgs: [pocketId, pocketId],
    );
    await loadPockets();
  }
}

final pocketProvider = StateNotifierProvider<PocketNotifier, AsyncValue<List<PocketWithBalance>>>((ref) {
  return PocketNotifier();
});

// Provider untuk menghitung total saldo seluruh kantong
final totalBalanceProvider = Provider<double>((ref) {
  final pocketsAsync = ref.watch(pocketProvider);
  return pocketsAsync.maybeWhen(
    data: (pockets) => pockets.fold<double>(0.0, (sum, p) => sum + p.currentBalance),
    orElse: () => 0.0,
  );
});
