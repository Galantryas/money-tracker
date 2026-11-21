import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/services/category_budget_repository.dart';
import 'package:money_tracker/models/category_budget.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('monthly usage excludes income, transfers and other months', () {
    TransactionModel tx(String type, double amount, DateTime date) => TransactionModel(
      id: '$type$amount', pocketId: 'p', type: type, amount: amount,
      category: 'Tempat Tinggal', merchant: '', note: '', date: date, createdAt: date,
    );
    final usage = CategoryBudgetUsage.calculate('Tempat Tinggal', 100, [
      tx('expense', 80, DateTime(2026, 11, 1)),
      tx('expense', 50, DateTime(2026, 10, 31)),
      tx('income', 90, DateTime(2026, 11, 2)),
      tx('transfer', 900, DateTime(2026, 11, 2)),
    ], DateTime(2026, 11));
    expect(usage.spent, 80);
    expect(usage.remaining, 20);
    expect(usage.isNearLimit, isTrue);
    expect(usage.isOverLimit, isFalse);
    const over = CategoryBudgetUsage('Tempat Tinggal', 100, 120);
    expect(over.isOverLimit, isTrue);
    expect(over.remaining, -20);
  });

  test('version one upgrade adds budgets without rewriting existing rows', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('budget_upgrade_');
    final file = '${dir.path}/old.db';
    final old = await openDatabase(file, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, icon_name TEXT, color_value INTEGER, type TEXT)');
      await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY, initial_balance REAL)');
      await db.insert('pockets', {'id': 'old', 'initial_balance': 12345.0});
    });
    await old.close();
    final upgraded = await AppDatabase.instance.openDatabaseAtPath(file);
    final repo = CategoryBudgetRepository(upgraded);
    expect(await repo.load(), isEmpty);
    await repo.setLimit('Tempat Tinggal', 500000);
    await repo.setLimit('Tempat Tinggal', 750000);
    expect(await repo.load(), {'Tempat Tinggal': 750000.0});
    await expectLater(repo.setLimit('Layanan', -1), throwsArgumentError);
    expect((await upgraded.query('pockets')).single['initial_balance'], 12345.0);
    await upgraded.close();
    final reopened = await AppDatabase.instance.openDatabaseAtPath(file);
    expect(await CategoryBudgetRepository(reopened).load(), {'Tempat Tinggal': 750000.0});
    await CategoryBudgetRepository(reopened).removeLimit('Tempat Tinggal');
    expect(await CategoryBudgetRepository(reopened).load(), isEmpty);
    await reopened.close();
    await dir.delete(recursive: true);
  });
}
