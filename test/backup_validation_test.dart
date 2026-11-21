import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/services/backup_service.dart';

void main() {
  final valid = <String, dynamic>{
    'app': 'Money Tracker',
    'version': 1,
    'data': {
      'pockets': <dynamic>[],
      'categories': <dynamic>[],
      'transactions': <dynamic>[],
    },
  };

  test('accepts an empty version one backup', () {
    expect(BackupService.validatePayload(valid), isNotNull);
  });

  test('rejects missing required sections instead of restoring empty data', () {
    expect(
      () => BackupService.validatePayload({
        'app': 'Money Tracker',
        'version': 1,
        'data': {'pockets': <dynamic>[]},
      }),
      throwsException,
    );
  });

  test('rejects a backup containing malformed records', () {
    expect(
      () => BackupService.validatePayload({
        ...valid,
        'data': {
          'pockets': [42],
          'categories': <dynamic>[],
          'transactions': <dynamic>[],
        },
      }),
      throwsException,
    );
  });

  test('accepts version one records including a transfer', () {
    final data = {
      'pockets': [
        {'id': 'a', 'name': 'Cash', 'icon_name': 'wallet', 'color_value': 1, 'initial_balance': 100, 'budget_limit': null, 'created_at': '2024-01-01T00:00:00.000'},
        {'id': 'b', 'name': 'Bank', 'icon_name': 'wallet', 'color_value': 2, 'initial_balance': 0, 'budget_limit': 50, 'created_at': '2024-01-01T00:00:00.000'},
      ],
      'categories': [
        {'id': 'c', 'name': 'Food', 'icon_name': 'food', 'color_value': 3, 'type': 'expense'},
      ],
      'transactions': [
        {'id': 't', 'pocket_id': 'a', 'target_pocket_id': 'b', 'type': 'transfer', 'amount': 20, 'category': 'Transfer', 'note': '', 'merchant': '', 'date': '2024-01-01T00:00:00.000', 'created_at': '2024-01-01T00:00:00.000'},
      ],
    };
    expect(BackupService.validatePayload({'app': 'Money Tracker', 'version': 1, 'data': data}), data);
  });

  test('accepts legacy backups with orphaned transactions without discarding them', () {
    final data = {
      'pockets': <dynamic>[],
      'categories': <dynamic>[],
      'transactions': [
        {'id': 't', 'pocket_id': 'missing', 'target_pocket_id': null, 'type': 'expense', 'amount': 10, 'category': 'Food', 'note': '', 'merchant': '', 'date': '2024-01-01T00:00:00.000', 'created_at': '2024-01-01T00:00:00.000'},
      ],
    };
    expect(BackupService.validatePayload({'app': 'Money Tracker', 'version': 1, 'data': data}), data);
    expect(BackupService.countMissingPocketReferences(data), 1);
  });

  test('validates optional budget limits without requiring them in old backups', () {
    final data = Map<String, dynamic>.from(valid['data'] as Map);
    data['category_budgets'] = [{'category': 'Tempat Tinggal', 'monthly_limit': 500000}];
    expect(BackupService.validatePayload({...valid, 'data': data}), data);
    data['category_budgets'] = [{'category': 'Tempat Tinggal', 'monthly_limit': -1}];
    expect(() => BackupService.validatePayload({...valid, 'data': data}), throwsException);
  });
}
