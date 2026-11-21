import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('restore failure rolls back the previous database contents', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY, pocket_id TEXT NOT NULL)');
    await db.insert('pockets', {'id': 'old', 'name': 'Saved pocket'});
    await db.insert('categories', {'id': 'old-category', 'name': 'Food'});
    await db.insert('transactions', {'id': 'old-transaction', 'pocket_id': 'old'});

    await expectLater(AppDatabase.instance.restoreToDatabase(db, {
      'pockets': [{'id': 'broken'}],
      'categories': <dynamic>[],
      'transactions': <dynamic>[],
    }), throwsException);
    expect(await db.query('pockets'), [{'id': 'old', 'name': 'Saved pocket'}]);
    expect(await db.query('transactions'), [{'id': 'old-transaction', 'pocket_id': 'old'}]);
    expect(await db.query('categories'), [{'id': 'old-category', 'name': 'Food'}]);
    await db.close();
  });

  test('restore retains version one pockets, categories and transfers', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY, name TEXT NOT NULL, initial_balance REAL NOT NULL)');
    await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY, pocket_id TEXT NOT NULL, target_pocket_id TEXT, type TEXT, amount REAL)');
    final data = {
      'pockets': [
        {'id': 'cash', 'name': 'Cash', 'initial_balance': 100.0},
        {'id': 'bank', 'name': 'Bank', 'initial_balance': 20.0},
      ],
      'categories': [{'id': 'c', 'name': 'Food'}],
      'transactions': [{'id': 't', 'pocket_id': 'cash', 'target_pocket_id': 'bank', 'type': 'transfer', 'amount': 30.0}],
    };
    await AppDatabase.instance.restoreToDatabase(db, data);
    expect(await db.query('pockets'), data['pockets']);
    expect(await db.query('categories'), data['categories']);
    expect(await db.query('transactions'), data['transactions']);
    await db.close();
  });

  test('budget restore is atomic and older backups remain importable', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY)');
    final data = <String, dynamic>{
      'pockets': [{'id': 'p'}], 'categories': <dynamic>[], 'transactions': <dynamic>[],
      'category_budgets': [{'category': 'Tempat Tinggal', 'monthly_limit': 123.0}],
    };
    await AppDatabase.instance.restoreToDatabase(db, data);
    expect(await db.query('category_budgets'), data['category_budgets']);
    await expectLater(AppDatabase.instance.restoreToDatabase(db, {
      ...data, 'category_budgets': [{'category': 'Tempat Tinggal', 'monthly_limit': -1}],
    }), throwsException);
    expect(await db.query('category_budgets'), data['category_budgets']);
    await AppDatabase.instance.restoreToDatabase(db, {
      'pockets': [{'id': 'p'}], 'categories': <dynamic>[], 'transactions': <dynamic>[],
    });
    expect(await db.query('category_budgets'), isEmpty);
    expect(await db.query('pockets'), [{'id': 'p'}]);
    await db.close();
  });

  test('opening a version one database retains pockets and transfers', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('money_tracker_upgrade_');
    final dbPath = path.join(dir.path, 'old.db');
    final old = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY, name TEXT, initial_balance REAL)');
      await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, icon_name TEXT, color_value INTEGER, type TEXT)');
      await db.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY, pocket_id TEXT, target_pocket_id TEXT, type TEXT, amount REAL)');
      await db.insert('pockets', {'id': 'cash', 'name': 'Cash', 'initial_balance': 100.0});
      await db.insert('pockets', {'id': 'bank', 'name': 'Bank', 'initial_balance': 20.0});
      await db.insert('categories', {'id': 'education', 'name': 'Pendidikan', 'icon_name': 'school', 'color_value': 5, 'type': 'expense'});
      await db.insert('transactions', {'id': 't1', 'pocket_id': 'cash', 'target_pocket_id': 'bank', 'type': 'transfer', 'amount': 30.0});
    });
    await old.close();

    final upgraded = await AppDatabase.instance.openDatabaseAtPath(dbPath);
    expect(await upgraded.getVersion(), 2);
    expect(await upgraded.query('pockets', orderBy: 'id'), [
      {'id': 'bank', 'name': 'Bank', 'initial_balance': 20.0},
      {'id': 'cash', 'name': 'Cash', 'initial_balance': 100.0},
    ]);
    expect(await upgraded.query('transactions'), [
      {'id': 't1', 'pocket_id': 'cash', 'target_pocket_id': 'bank', 'type': 'transfer', 'amount': 30.0},
    ]);
    expect(await upgraded.query('categories', where: 'id = ?', whereArgs: ['education']), [
      {'id': 'education', 'name': 'Pendidikan', 'icon_name': 'school', 'color_value': 5, 'type': 'expense'},
    ]);
    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
