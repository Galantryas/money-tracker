import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/services/notification_service.dart';

class ReminderState {
  final bool isEnabled;
  final TimeOfDay time;

  const ReminderState({
    required this.isEnabled,
    required this.time,
  });

  ReminderState copyWith({
    bool? isEnabled,
    TimeOfDay? time,
  }) {
    return ReminderState(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyEnabled = 'reminder_enabled';
  static const String _keyHour = 'reminder_hour';
  static const String _keyMinute = 'reminder_minute';

  ReminderNotifier()
      : super(const ReminderState(
          isEnabled: true,
          time: TimeOfDay(hour: 20, minute: 0),
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabledStr = await _storage.read(key: _keyEnabled);
      final hourStr = await _storage.read(key: _keyHour);
      final minuteStr = await _storage.read(key: _keyMinute);

      final isEnabled = enabledStr == null ? true : enabledStr == 'true';
      final hour = hourStr != null ? int.tryParse(hourStr) ?? 20 : 20;
      final minute = minuteStr != null ? int.tryParse(minuteStr) ?? 0 : 0;

      final loadedTime = TimeOfDay(hour: hour, minute: minute);
      state = ReminderState(isEnabled: isEnabled, time: loadedTime);

      if (isEnabled) {
        await NotificationService.scheduleDailyReminder(
          hour: hour,
          minute: minute,
        );
      }
    } catch (e) {
      debugPrint('Error loading reminder settings: $e');
    }
  }

  Future<void> toggleReminder(bool isEnabled) async {
    state = state.copyWith(isEnabled: isEnabled);
    await _storage.write(key: _keyEnabled, value: isEnabled.toString());

    if (isEnabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyReminder(
        hour: state.time.hour,
        minute: state.time.minute,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> setTime(TimeOfDay newTime) async {
    state = state.copyWith(time: newTime);
    await _storage.write(key: _keyHour, value: newTime.hour.toString());
    await _storage.write(key: _keyMinute, value: newTime.minute.toString());

    if (state.isEnabled) {
      await NotificationService.scheduleDailyReminder(
        hour: newTime.hour,
        minute: newTime.minute,
      );
    }
  }

  Future<void> testNotification() async {
    await NotificationService.showTestNotification();
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier();
});
