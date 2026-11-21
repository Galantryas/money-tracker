import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/async_action_guard.dart';

void main() {
  test('runs only one save at a time and allows retry after failure', () async {
    final guard = AsyncActionGuard();
    final pending = Completer<void>();
    var calls = 0;
    final first = guard.run(() { calls++; return pending.future; });
    await guard.run(() async { calls++; });
    expect(calls, 1);
    pending.completeError(Exception('failed'));
    await expectLater(first, throwsException);
    await guard.run(() async { calls++; });
    expect(calls, 2);
  });
}
