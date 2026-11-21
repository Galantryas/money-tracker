import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int reminderNotificationId = 888;
  static bool _isInitialized = false;
  static const MethodChannel _timeZoneChannel = MethodChannel('money_tracker/timezone');

  @visibleForTesting
  static Future<tz.Location> readDeviceTimeZone() async {
    final name = await _timeZoneChannel.invokeMethod<String>('getLocalTimeZone');
    if (name == null || name.isEmpty) throw Exception('Zona waktu perangkat tidak tersedia.');
    return tz.getLocation(name);
  }

  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      // Inisialisasi zona waktu
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init exception: $e');
    }
  }

  static Future<bool?> requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('requestPermission error: $e');
        return false;
      }
    }
    return true;
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('Pengingat belum didukung pada perangkat ini.');
    }
    if (!_isInitialized) await init();
    if (!_isInitialized) throw Exception('Layanan notifikasi tidak tersedia.');

    try {
      tz.setLocalLocation(await readDeviceTimeZone());
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null || await androidPlugin.areNotificationsEnabled() == false) {
        throw Exception('Izin notifikasi belum diberikan.');
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'money_tracker_daily_reminder',
        'Pengingat Harian',
        channelDescription: 'Alarm dan notifikasi pengingat untuk mencatat keuangan setiap hari',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        reminderNotificationId,
        'Waktunya Mencatat Keuangan! 📝',
        'Sudahkah kamu mencatat pengeluaran & pemasukanmu hari ini? Yuk catat sekarang agar keuanganmu tetap rapi!',
        _nextInstanceOfTime(hour, minute),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Daily reminder scheduled for $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
      rethrow;
    }
  }

  static Future<void> cancelDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(reminderNotificationId);
      debugPrint('Daily reminder cancelled');
    } catch (e) {
      debugPrint('Error cancelling daily reminder: $e');
      rethrow;
    }
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb || !Platform.isAndroid) {
      throw UnsupportedError('Notifikasi belum didukung pada perangkat ini.');
    }
    if (!_isInitialized) await init();
    if (!_isInitialized) throw Exception('Layanan notifikasi tidak tersedia.');

    try {
      if (await requestPermission() != true) throw Exception('Izin notifikasi belum diberikan.');

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'money_tracker_daily_reminder',
        'Pengingat Harian',
        channelDescription: 'Alarm dan notifikasi pengingat untuk mencatat keuangan setiap hari',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notificationsPlugin.show(
        0,
        'Tes Pengingat Money Tracker 🔔',
        'Alarm pengingat harian berhasil diatur! Anda akan menerima notifikasi ini setiap hari pada jam yang dipilih.',
        platformDetails,
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
      rethrow;
    }
  }
}
