import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('money_tracker/timezone');

  test('uses the device IANA time zone rather than a fixed zone', () async {
    tz.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'Asia/Makassar');
    expect((await NotificationService.readDeviceTimeZone()).name, 'Asia/Makassar');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('rejects an unknown zone instead of scheduling in the wrong zone', () async {
    tz.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'not/a-zone');
    await expectLater(NotificationService.readDeviceTimeZone(), throwsException);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
