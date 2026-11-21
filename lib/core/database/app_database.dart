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
    return openDatabaseAtPath(path);
  }

  @visibleForTesting
  Future<Database> openDatabaseAtPath(String path) async {
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createBudgetTable(db);
      },
      onOpen: (db) async {
        await _ensureCategories(db);
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await _createBudgetTable(db);
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
      {'id': uuid.v4(), 'name': 'Tempat Tinggal', 'icon_name': 'home', 'color_value': 0xFF0D9488, 'type': 'expense'},
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

  static Future<void> _createBudgetTable(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS category_budgets (
      category TEXT PRIMARY KEY NOT NULL,
      monthly_limit REAL NOT NULL CHECK (monthly_limit > 0)
    )''');
  }

  Future<List<Map<String, dynamic>>> loadCategories(Database db) async {
    return db.transaction((txn) async {
      await _ensureCategories(txn);
      return txn.query('categories');
    });
  }

  static Future<void> _ensureCategories(DatabaseExecutor db) async {
    const uuid = Uuid();
    final expectedExpenses = [
      {'name': 'Makanan & Minuman', 'icon_name': 'utensils', 'color_value': 0xFFF97316},
      {'name': 'Belanja', 'icon_name': 'shopping_bag', 'color_value': 0xFF3B82F6},
      {'name': 'Transportasi', 'icon_name': 'car', 'color_value': 0xFFEAB308},
      {'name': 'Layanan', 'icon_name': 'receipt', 'color_value': 0xFF6366F1},
      {'name': 'Tempat Tinggal', 'icon_name': 'home', 'color_value': 0xFF0D9488},
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
    return db.transaction((txn) async => {
      'pockets': await txn.query('pockets'),
      'categories': await txn.query('categories'),
      'transactions': await txn.query('transactions'),
      'category_budgets': await txn.query('category_budgets'),
    });
  }

  Future<void> restoreAllData(Map<String, dynamic> data) async {
    final db = await instance.database;
    await restoreToDatabase(db, data);
  }

  @visibleForTesting
  Future<void> restoreToDatabase(Database db, Map<String, dynamic> data) async {
    final pockets = (data['pockets'] as List<dynamic>? ?? []);
    final categories = (data['categories'] as List<dynamic>? ?? []);
    final transactions = (data['transactions'] as List<dynamic>? ?? []);

    await db.transaction((txn) async {
      await _createBudgetTable(txn);
      await txn.delete('category_budgets');
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
      for (final budget in (data['category_budgets'] as List? ?? [])) {
        await txn.insert('category_budgets', Map<String, dynamic>.from(budget as Map));
      }
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
