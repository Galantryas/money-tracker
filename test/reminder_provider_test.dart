import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/providers/reminder_provider.dart';

class FakeReminderBackend implements ReminderBackend {
  bool permission = true;
  bool failSchedule = false;
  int scheduled = 0;
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<void> schedule(int hour, int minute) async {
    if (failSchedule) throw Exception('schedule failed');
    scheduled++;
  }
  @override
  Future<void> cancel() async {}
  @override
  Future<void> test() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('denied notification permission does not enable a reminder', () async {
    FlutterSecureStorage.setMockInitialValues({'reminder_enabled': 'false'});
    final backend = FakeReminderBackend()..permission = false;
    final notifier = ReminderNotifier(backend: backend);
    await notifier.ready;
    await notifier.toggleReminder(true);
    expect(notifier.state.isEnabled, false);
    expect(notifier.state.errorMessage, isNotNull);
    expect(backend.scheduled, 0);
    expect(await const FlutterSecureStorage().read(key: 'reminder_enabled'), 'false');
    notifier.dispose();
  });

  test('failed scheduling keeps the previous reminder time', () async {
    FlutterSecureStorage.setMockInitialValues({'reminder_enabled': 'true', 'reminder_hour': '20', 'reminder_minute': '0'});
    final backend = FakeReminderBackend();
    final notifier = ReminderNotifier(backend: backend);
    await notifier.ready;
    backend.failSchedule = true;
    await notifier.setTime(const TimeOfDay(hour: 9, minute: 30));
    expect(notifier.state.time, const TimeOfDay(hour: 20, minute: 0));
    expect(notifier.state.errorMessage, isNotNull);
    expect(await const FlutterSecureStorage().read(key: 'reminder_hour'), '20');
    notifier.dispose();
  });
}
