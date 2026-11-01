import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await _ensureCategories(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel Kantong
    await db.execute('''
      CREATE TABLE pockets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        initial_balance REAL NOT NULL,
        budget_limit REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel Kategori
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        pocket_id TEXT NOT NULL,
        target_pocket_id TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL,
        merchant TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (pocket_id) REFERENCES pockets (id) ON DELETE CASCADE
      )
    ''');

    // Seed default categories
    const uuid = Uuid();
    final defaultCategories = [
      // Expense: 7 kategori yang diminta pengguna
      {'id': uuid.v4(), 'name': 'Makanan & Minuman', 'icon_name': 'utensils', 'color_value': 0xFFF97316, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Belanja', 'icon_name': 'shopping_bag', 'color_value': 0xFF3B82F6, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Transportasi', 'icon_name': 'car', 'color_value': 0xFFEAB308, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Layanan', 'icon_name': 'receipt', 'color_value': 0xFF6366F1, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Hiburan', 'icon_name': 'film', 'color_value': 0xFF8B5CF6, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Kesehatan', 'icon_name': 'heart_pulse', 'color_value': 0xFFEC4899, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Keluarga', 'icon_name': 'family', 'color_value': 0xFF06B6D4, 'type': 'expense'},
      {'id': uuid.v4(), 'name': 'Pengeluaran Lain', 'icon_name': 'more_horizontal', 'color_value': 0xFF64748B, 'type': 'expense'},

      // Income
      {'id': uuid.v4(), 'name': 'Gaji Bulanan', 'icon_name': 'banknote', 'color_value': 0xFF10B981, 'type': 'income'},
      {'id': uuid.v4(), 'name': 'Bonus & THR', 'icon_name': 'gift', 'color_value': 0xFF059669, 'type': 'income'},
      {'id': uuid.v4(), 'name': 'Hasil Investasi', 'icon_name': 'trending_up', 'color_value': 0xFF0D9488, 'type': 'income'},
      {'id': uuid.v4(), 'name': 'Freelance / Bisnis', 'icon_name': 'laptop', 'color_value': 0xFF6366F1, 'type': 'income'},
      {'id': uuid.v4(), 'name': 'Pemasukan Lain', 'icon_name': 'plus_circle', 'color_value': 0xFF64748B, 'type': 'income'},
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  static Future<void> _ensureCategories(Database db) async {
    const uuid = Uuid();
    // Normalisasi / migrasi kategori lama jika ada
    await db.rawUpdate("UPDATE categories SET name = 'Belanja' WHERE name = 'Belanja Kebutuhan'");
    await db.rawUpdate("UPDATE categories SET name = 'Layanan' WHERE name = 'Tagihan & Listrik'");
    await db.rawUpdate("UPDATE categories SET name = 'Hiburan' WHERE name = 'Hiburan & Liburan'");
    await db.rawUpdate("UPDATE categories SET name = 'Pengeluaran Lain' WHERE name = 'Lain-lain'");
    await db.rawUpdate("UPDATE categories SET name = 'Layanan' WHERE name = 'Pendidikan'");

    final expectedExpenses = [
      {'name': 'Makanan & Minuman', 'icon_name': 'utensils', 'color_value': 0xFFF97316},
      {'name': 'Belanja', 'icon_name': 'shopping_bag', 'color_value': 0xFF3B82F6},
      {'name': 'Transportasi', 'icon_name': 'car', 'color_value': 0xFFEAB308},
      {'name': 'Layanan', 'icon_name': 'receipt', 'color_value': 0xFF6366F1},
      {'name': 'Hiburan', 'icon_name': 'film', 'color_value': 0xFF8B5CF6},
      {'name': 'Kesehatan', 'icon_name': 'heart_pulse', 'color_value': 0xFFEC4899},
      {'name': 'Keluarga', 'icon_name': 'family', 'color_value': 0xFF06B6D4},
      {'name': 'Pengeluaran Lain', 'icon_name': 'more_horizontal', 'color_value': 0xFF64748B},
    ];

    final existing = await db.query('categories', where: 'type = ?', whereArgs: ['expense']);
    final existingNames = existing.map((e) => e['name'] as String).toSet();

    for (final exp in expectedExpenses) {
      if (!existingNames.contains(exp['name'])) {
        await db.insert('categories', {
          'id': uuid.v4(),
          'name': exp['name'],
          'icon_name': exp['icon_name'],
          'color_value': exp['color_value'],
          'type': 'expense',
        });
      }
    }
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await instance.database;
    final pockets = await db.query('pockets');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');

    return {
      'pockets': pockets,
      'categories': categories,
      'transactions': transactions,
    };
  }

  Future<void> restoreAllData(Map<String, dynamic> data) async {
    final db = await instance.database;
    final pockets = (data['pockets'] as List<dynamic>? ?? []);
    final categories = (data['categories'] as List<dynamic>? ?? []);
    final transactions = (data['transactions'] as List<dynamic>? ?? []);

    await db.transaction((txn) async {
      // Hapus data yang ada sekarang
      await txn.delete('transactions');
      await txn.delete('pockets');
      await txn.delete('categories');

      // Pulihkan Kategori
      if (categories.isNotEmpty) {
        for (final cat in categories) {
          if (cat is Map) {
            await txn.insert('categories', Map<String, dynamic>.from(cat));
          }
        }
      }

      // Pulihkan Kantong
      for (final pocket in pockets) {
        if (pocket is Map) {
          await txn.insert('pockets', Map<String, dynamic>.from(pocket));
        }
      }

      // Pulihkan Transaksi
      for (final tx in transactions) {
        if (tx is Map) {
          await txn.insert('transactions', Map<String, dynamic>.from(tx));
        }
      }
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
