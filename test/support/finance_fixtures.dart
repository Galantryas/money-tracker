import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_tracker/models/pocket.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/providers/pocket_provider.dart';
import 'package:money_tracker/providers/transaction_provider.dart';
import 'package:money_tracker/providers/auth_provider.dart';
import 'package:money_tracker/core/security/biometric_service.dart';
import 'package:money_tracker/providers/gemini_provider.dart';
import 'package:money_tracker/services/gemini_service.dart';

class FixtureGeminiService extends GeminiService {
  @override
  Future<String?> getApiKey() async => null;
}

class FixtureBiometrics extends BiometricService {
  @override
  Future<bool> isDeviceSupported() async => false;
  @override
  Future<bool> isBiometricEnabled() async => false;
  @override
  Future<bool> hasPin() async => true;
  @override
  Future<bool> authenticate({String reason = ''}) async => false;
}

final fixtureMonth = DateTime(2026, 11);
final fixtureTransactions = [
  TransactionModel(
      id: 'expense',
      pocketId: 'p',
      type: 'expense',
      amount: 850000,
      category: 'Tempat Tinggal',
      merchant: 'Sewa',
      note: 'Sewa bulanan',
      date: DateTime.now(),
      createdAt: DateTime.now()),
  TransactionModel(
      id: 'income',
      pocketId: 'p',
      type: 'income',
      amount: 3000000,
      category: 'Gaji',
      merchant: '',
      note: '',
      date: DateTime.now(),
      createdAt: DateTime.now()),
  TransactionModel(
      id: 'old',
      pocketId: 'p',
      type: 'expense',
      amount: 12345,
      category: 'Layanan',
      merchant: '',
      note: '',
      date: DateTime(2020),
      createdAt: DateTime(2020)),
];

class FixtureTransactions extends TransactionNotifier {
  FixtureTransactions(super.ref) {
    state = AsyncValue.data(fixtureTransactions);
  }
  @override
  Future<void> loadTransactions() async {}
}

class FixturePockets extends PocketNotifier {
  FixturePockets() {
    state = AsyncValue.data([
      PocketWithBalance(
          pocket: Pocket(
              id: 'p',
              name: 'Kantong Utama',
              iconName: 'wallet',
              colorValue: 0xFF6366F1,
              initialBalance: 0,
              createdAt: DateTime(2020)),
          currentBalance: 2137655,
          incomeThisMonth: 3000000,
          spentThisMonth: 850000),
    ]);
  }
  @override
  Future<void> loadPockets() async {}
}

List<Override> financeOverrides() => [
      biometricServiceProvider.overrideWithValue(FixtureBiometrics()),
      geminiServiceProvider.overrideWithValue(FixtureGeminiService()),
      transactionProvider.overrideWith((ref) => FixtureTransactions(ref)),
      pocketProvider.overrideWith((ref) => FixturePockets()),
      categoriesProvider.overrideWith((ref) async => [
            {
              'id': 's',
              'name': 'Layanan',
              'type': 'expense',
              'icon_name': 'receipt',
              'color_value': 0xFF6366F1
            },
            {
              'id': 'h',
              'name': 'Tempat Tinggal',
              'type': 'expense',
              'icon_name': 'home',
              'color_value': 0xFF0D9488
            },
            {
              'id': 'i',
              'name': 'Gaji',
              'type': 'income',
              'icon_name': 'banknote',
              'color_value': 0xFF10B981
            },
          ]),
    ];
