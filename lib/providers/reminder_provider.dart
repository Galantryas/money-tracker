import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/services/notification_service.dart';

abstract class ReminderBackend {
  Future<bool> requestPermission();
  Future<void> schedule(int hour, int minute);
  Future<void> cancel();
  Future<void> test();
}

class DeviceReminderBackend implements ReminderBackend {
  @override
  Future<bool> requestPermission() async => await NotificationService.requestPermission() ?? false;
  @override
  Future<void> schedule(int hour, int minute) => NotificationService.scheduleDailyReminder(hour: hour, minute: minute);
  @override
  Future<void> cancel() => NotificationService.cancelDailyReminder();
  @override
  Future<void> test() => NotificationService.showTestNotification();
}

class ReminderState {
  final bool isEnabled;
  final TimeOfDay time;
  final String? errorMessage;

  const ReminderState({
    required this.isEnabled,
    required this.time,
    this.errorMessage,
  });

  ReminderState copyWith({
    bool? isEnabled,
    TimeOfDay? time,
    String? errorMessage,
  }) {
    return ReminderState(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
      errorMessage: errorMessage,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ReminderBackend _backend;
  late final Future<void> ready;
  static const String _keyEnabled = 'reminder_enabled';
  static const String _keyHour = 'reminder_hour';
  static const String _keyMinute = 'reminder_minute';

  ReminderNotifier({ReminderBackend? backend})
      : _backend = backend ?? DeviceReminderBackend(),
        super(const ReminderState(
          isEnabled: true,
          time: TimeOfDay(hour: 20, minute: 0),
        )) {
    ready = _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabledStr = await _storage.read(key: _keyEnabled);
      final hourStr = await _storage.read(key: _keyHour);
      final minuteStr = await _storage.read(key: _keyMinute);
      if (!mounted) return;

      final isEnabled = enabledStr == null ? true : enabledStr == 'true';
      final hour = hourStr != null ? int.tryParse(hourStr) ?? 20 : 20;
      final minute = minuteStr != null ? int.tryParse(minuteStr) ?? 0 : 0;

      final loadedTime = TimeOfDay(hour: hour, minute: minute);
      state = ReminderState(isEnabled: isEnabled, time: loadedTime);

      if (isEnabled) {
        await _backend.schedule(hour, minute);
      }
    } catch (e) {
      if (mounted) state = state.copyWith(errorMessage: 'Pengingat tidak dapat dijadwalkan. Periksa izin notifikasi dan coba lagi.');
    }
  }

  Future<void> toggleReminder(bool isEnabled) async {
    try {
      if (isEnabled) {
        if (!await _backend.requestPermission()) throw Exception('permission denied');
        await _backend.schedule(state.time.hour, state.time.minute);
      } else {
        await _backend.cancel();
      }
      await _storage.write(key: _keyEnabled, value: isEnabled.toString());
      if (mounted) state = state.copyWith(isEnabled: isEnabled);
    } catch (_) {
      if (mounted) state = state.copyWith(errorMessage: 'Pengingat tidak dapat diubah. Periksa izin notifikasi dan coba lagi.');
    }
  }

  Future<void> setTime(TimeOfDay newTime) async {
    try {
      if (state.isEnabled) await _backend.schedule(newTime.hour, newTime.minute);
      await _storage.write(key: _keyHour, value: newTime.hour.toString());
      await _storage.write(key: _keyMinute, value: newTime.minute.toString());
      if (mounted) state = state.copyWith(time: newTime);
    } catch (_) {
      if (mounted) state = state.copyWith(errorMessage: 'Waktu pengingat tidak dapat disimpan. Periksa izin notifikasi dan coba lagi.');
    }
  }

  Future<void> testNotification() async {
    await _backend.test();
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier();
});
