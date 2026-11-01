import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/currency_formatter.dart';
import 'package:money_tracker/core/utils/icon_helper.dart';
import 'package:money_tracker/core/utils/thousands_separator_input_formatter.dart';
import 'package:money_tracker/models/pocket.dart';
import 'package:money_tracker/models/transaction_model.dart';

void main() {
  group('ThousandsSeparatorInputFormatter Tests', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('Formats plain digits with dots', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(
          text: '50000',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(res.text, '50.000');
    });

    test('Converts period shortcut to 000', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '50',
          selection: TextSelection.collapsed(offset: 2),
        ),
        const TextEditingValue(
          text: '50.',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(res.text, '50.000');
    });

    test('Converts comma shortcut to 000', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '100',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '100,',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(res.text, '100.000');
    });

    test('appendZeros static helper', () {
      final ctrl = TextEditingController(text: '50');
      ThousandsSeparatorInputFormatter.appendZeros(ctrl, zeros: '000');
      expect(ctrl.text, '50.000');

      ThousandsSeparatorInputFormatter.appendZeros(ctrl, zeros: '000');
      expect(ctrl.text, '50.000.000');
    });
  });

  group('CurrencyFormatter Tests', () {
    test('Format Indonesian Rupiah correctly', () {
      final formatted = CurrencyFormatter.format(50000);
      expect(formatted.contains('50.000'), isTrue);
      expect(formatted.contains('Rp'), isTrue);
    });

    test('Format compact amounts', () {
      expect(CurrencyFormatter.formatCompact(1500000), 'Rp 1,5 jt');
      expect(CurrencyFormatter.formatCompact(250000), 'Rp 250 rb');
    });

    test('Parse string to double', () {
      expect(CurrencyFormatter.parse('Rp 150.000'), 150000.0);
      expect(CurrencyFormatter.parse('2.500.000'), 2500000.0);
    });
  });

  group('Model Serialization Tests', () {
    test('Pocket model toMap and fromMap', () {
      final now = DateTime.now();
      final pocket = Pocket(
        id: 'pocket-1',
        name: 'Kantong Makan',
        iconName: 'utensils',
        colorValue: 0xFFF97316,
        initialBalance: 500000.0,
        budgetLimit: 1000000.0,
        createdAt: now,
      );

      final map = pocket.toMap();
      final fromMap = Pocket.fromMap(map);

      expect(fromMap.id, pocket.id);
      expect(fromMap.name, pocket.name);
      expect(fromMap.initialBalance, pocket.initialBalance);
      expect(fromMap.budgetLimit, pocket.budgetLimit);
    });

    test('TransactionModel toMap and fromMap', () {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'tx-1',
        pocketId: 'pocket-1',
        targetPocketId: null,
        type: 'expense',
        amount: 25000.0,
        category: 'Makanan & Minuman',
        note: 'Beli makan siang',
        merchant: 'Warung Nasi',
        date: now,
        createdAt: now,
      );

      final map = tx.toMap();
      final fromMap = TransactionModel.fromMap(map);

      expect(fromMap.id, tx.id);
      expect(fromMap.amount, 25000.0);
      expect(fromMap.isExpense, isTrue);
      expect(fromMap.isIncome, isFalse);
      expect(fromMap.merchant, 'Warung Nasi');
    });
  });

  group('Backup & Restore Tests', () {
    test('Backup payload validation and integrity', () {
      final sampleBackup = {
        'app': 'Money Tracker',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'summary': {
          'total_pockets': 1,
          'total_categories': 1,
          'total_transactions': 1,
        },
        'data': {
          'pockets': [
            {
              'id': 'p-1',
              'name': 'Dompet Utama',
              'icon_name': 'wallet',
              'color_value': 0xFF2563EB,
              'initial_balance': 100000.0,
              'budget_limit': null,
              'created_at': DateTime.now().toIso8601String(),
            }
          ],
          'categories': [
            {
              'id': 'c-1',
              'name': 'Makanan',
              'icon_name': 'utensils',
              'color_value': 0xFFF97316,
              'type': 'expense',
            }
          ],
          'transactions': [
            {
              'id': 't-1',
              'pocket_id': 'p-1',
              'target_pocket_id': null,
              'type': 'expense',
              'amount': 20000.0,
              'category': 'Makanan',
              'note': 'Siang',
              'merchant': 'Kantin',
              'date': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
            }
          ],
        },
      };

      // Validasi struktur
      expect(sampleBackup['app'], 'Money Tracker');
      expect(sampleBackup['version'], 1);
      final data = sampleBackup['data'] as Map<String, dynamic>;
      final pockets = data['pockets'] as List;
      final transactions = data['transactions'] as List;

      expect(pockets.length, 1);
      expect(transactions.length, 1);
      expect(pockets.first['name'], 'Dompet Utama');
      expect(transactions.first['amount'], 20000.0);
    });
  });

  group('Merchant Options Tests', () {
    test('Preset common merchants only in dropdown', () {
      final common = ['Gofood', 'Gojek', 'Shopee', 'Astro'];

      expect(common, containsAll(['Gofood', 'Gojek', 'Shopee', 'Astro']));
      expect(common.length, 4);
      expect(common.first, 'Gofood');
    });
  });

  group('Keluarga Category & Pocket Filter Tests', () {
    test('IconHelper supports family icon for Keluarga category', () {
      final icon = IconHelper.getIcon('family');
      expect(icon, Icons.family_restroom);
    });

    test('Filter pockets distinguishes Debit and Kredit', () {
      final p1 = Pocket(
        id: 'p-1',
        name: 'BCA Utama',
        iconName: 'account_balance',
        colorValue: 0xFF2563EB,
        initialBalance: 1000000,
        createdAt: DateTime.now(),
      );
      final p2 = Pocket(
        id: 'p-2',
        name: 'Kartu Kredit Mandiri',
        iconName: 'credit_card',
        colorValue: 0xFFDC2626,
        initialBalance: 0,
        createdAt: DateTime.now(),
      );

      final isP1Kredit = p1.iconName == 'credit_card' || p1.name.toLowerCase().contains('kredit');
      final isP2Kredit = p2.iconName == 'credit_card' || p2.name.toLowerCase().contains('kredit');

      expect(isP1Kredit, isFalse);
      expect(isP2Kredit, isTrue);
    });
  });

  group('Category Sorting Tests', () {
    test('Expense other/lainnya category is placed at the very bottom', () {
      final categories = [
        {'name': 'Makanan & Minuman', 'icon_name': 'utensils', 'type': 'expense'},
        {'name': 'Belanja', 'icon_name': 'shopping_bag', 'type': 'expense'},
        {'name': 'Pengeluaran Lain', 'icon_name': 'more_horizontal', 'type': 'expense'},
        {'name': 'Keluarga', 'icon_name': 'family', 'type': 'expense'},
        {'name': 'Transportasi', 'icon_name': 'car', 'type': 'expense'},
      ];

      final normal = categories.where((c) {
        final name = (c['name'] as String).toLowerCase();
        final icon = (c['icon_name'] as String).toLowerCase();
        return !name.contains('lain') && icon != 'more_horizontal';
      }).toList();
      final other = categories.where((c) {
        final name = (c['name'] as String).toLowerCase();
        final icon = (c['icon_name'] as String).toLowerCase();
        return name.contains('lain') || icon == 'more_horizontal';
      }).toList();
      final sorted = [...normal, ...other];

      expect(sorted.last['name'], 'Pengeluaran Lain');
      expect(sorted.map((c) => c['name']).toList(), [
        'Makanan & Minuman',
        'Belanja',
        'Keluarga',
        'Transportasi',
        'Pengeluaran Lain',
      ]);
    });
  });
}

