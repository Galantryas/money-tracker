import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/database/app_database.dart';
import 'package:money_tracker/core/utils/category_order.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('housing follows services even when appended during an upgrade', () {
    final rows = [
      {'name': 'Makanan & Minuman', 'type': 'expense'},
      {'name': 'Layanan', 'type': 'expense'},
      {'name': 'Hiburan', 'type': 'expense'},
      {'name': 'Pengeluaran Lain', 'type': 'expense', 'icon_name': 'more_horizontal'},
      {'name': 'Tempat Tinggal', 'type': 'expense'},
      {'name': 'Gaji', 'type': 'income'},
    ];
    expect(orderCategories(rows).map((row) => row['name']), [
      'Makanan & Minuman', 'Layanan', 'Tempat Tinggal', 'Hiburan', 'Pengeluaran Lain', 'Gaji',
    ]);
    expect(rows[4]['name'], 'Tempat Tinggal');
  });

  test('existing database gets housing exactly once without rewriting categories', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('housing_upgrade_');
    final file = '${dir.path}/old.db';
    final old = await openDatabase(file, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, icon_name TEXT, color_value INTEGER, type TEXT)');
      await db.insert('categories', {'id': 'existing', 'name': 'Layanan', 'icon_name': 'receipt', 'color_value': 123, 'type': 'expense'});
    });
    await old.close();
    for (var i = 0; i < 2; i++) {
      final db = await AppDatabase.instance.openDatabaseAtPath(file);
      final housing = await db.query('categories', where: 'name = ? AND type = ?', whereArgs: ['Tempat Tinggal', 'expense']);
      expect(housing, hasLength(1));
      expect(housing.single['icon_name'], 'home');
      expect((await db.query('categories', where: 'id = ?', whereArgs: ['existing'])).single['color_value'], 123);
      if (i == 0) {
        await db.delete('categories', where: 'name = ?', whereArgs: ['Tempat Tinggal']);
        final reloaded = await AppDatabase.instance.loadCategories(db);
        expect(reloaded.where((row) => row['name'] == 'Tempat Tinggal'), hasLength(1));
      }
      await db.close();
    }
    await dir.delete(recursive: true);
  });
}
