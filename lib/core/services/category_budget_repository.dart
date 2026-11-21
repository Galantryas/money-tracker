import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CategoryBudgetRepository {
  final Database database;
  CategoryBudgetRepository(this.database);

  Future<Map<String, double>> load() async {
    final rows = await database.query('category_budgets', orderBy: 'category ASC');
    return {for (final row in rows) row['category'] as String: (row['monthly_limit'] as num).toDouble()};
  }

  Future<void> setLimit(String category, double limit) async {
    if (category.trim().isEmpty || !limit.isFinite || limit <= 0) {
      throw ArgumentError('Anggaran harus lebih dari nol.');
    }
    await database.insert('category_budgets', {'category': category, 'monthly_limit': limit},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeLimit(String category) async {
    await database.delete('category_budgets', where: 'category = ?', whereArgs: [category]);
  }
}
