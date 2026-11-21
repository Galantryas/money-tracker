import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/providers/pocket_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('deletion refuses to remove a pocket linked to a transfer', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE pockets (id TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE transactions (id TEXT PRIMARY KEY, pocket_id TEXT, target_pocket_id TEXT, type TEXT)');
    await db.insert('pockets', {'id': 'a'});
    await db.insert('pockets', {'id': 'b'});
    await db.insert('transactions', {'id': 't', 'pocket_id': 'a', 'target_pocket_id': 'b', 'type': 'transfer'});

    await expectLater(PocketNotifier.deletePocketSafely(db, 'b'), throwsException);
    expect(await db.query('pockets'), hasLength(2));
    expect(await db.query('transactions'), hasLength(1));
    await db.close();
  });
}
