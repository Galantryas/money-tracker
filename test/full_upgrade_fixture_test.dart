import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('full version-one records retain their exact fields after migration', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory = await Directory.systemTemp.createTemp('full_upgrade_');
    final file = '${directory.path}/money_tracker.db';
    final old = await openDatabase(file, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY, name TEXT NOT NULL, icon_name TEXT NOT NULL, color_value INTEGER NOT NULL, initial_balance REAL NOT NULL, budget_limit REAL, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT NOT NULL, icon_name TEXT NOT NULL, color_value INTEGER NOT NULL, type TEXT NOT NULL)');
      await db.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY, pocket_id TEXT NOT NULL, target_pocket_id TEXT, type TEXT NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL, note TEXT NOT NULL, merchant TEXT NOT NULL, date TEXT NOT NULL, created_at TEXT NOT NULL)');
    });
    final pockets = [
      {'id': 'a', 'name': 'Tunai', 'icon_name': 'wallet', 'color_value': 123, 'initial_balance': 5000000.0, 'budget_limit': 1000000.0, 'created_at': '2024-01-01T00:00:00.000'},
      {'id': 'b', 'name': 'Bank', 'icon_name': 'credit_card', 'color_value': 456, 'initial_balance': 0.0, 'budget_limit': null, 'created_at': '2024-02-01T00:00:00.000'},
    ];
    const category = {'id': 'custom', 'name': 'Pendidikan', 'icon_name': 'book', 'color_value': 999, 'type': 'expense'};
    final transactions = [
      for (final type in ['income', 'expense', 'transfer'])
        {'id': type, 'pocket_id': 'a', 'target_pocket_id': type == 'transfer' ? 'b' : null,
          'type': type, 'amount': 12345.0, 'category': 'Pendidikan', 'note': 'Catatan lama',
          'merchant': 'Toko lama', 'date': '2024-03-01T23:59:59.000', 'created_at': '2024-03-02T00:00:00.000'},
    ];
    for (final pocket in pockets) { await old.insert('pockets', pocket); }
    await old.insert('categories', category);
    for (final tx in transactions) { await old.insert('transactions', tx); }
    await old.close();

    final upgraded = await AppDatabase.instance.openDatabaseAtPath(file);
    expect(await upgraded.query('pockets', orderBy: 'id'), pockets);
    expect(await upgraded.query('transactions', orderBy: 'rowid'), transactions);
    expect((await upgraded.query('categories', where: 'id = ?', whereArgs: ['custom'])).single, category);
    expect(await upgraded.query('category_budgets'), isEmpty);
    expect(await upgraded.query('categories', where: 'name = ?', whereArgs: ['Tempat Tinggal']), hasLength(1));
    await upgraded.close();
    await directory.delete(recursive: true);
  });
}
