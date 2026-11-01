import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'views/auth/lock_screen.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('id_ID', null);
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: MoneyTrackerApp(),
    ),
  );
}

class MoneyTrackerApp extends ConsumerStatefulWidget {
  const MoneyTrackerApp({super.key});

  @override
  ConsumerState<MoneyTrackerApp> createState() => _MoneyTrackerAppState();
}

class _MoneyTrackerAppState extends ConsumerState<MoneyTrackerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Kunci aplikasi otomatis ketika diminimalkan
      ref.read(authProvider.notifier).lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Money Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.isUnlocked ? const MainNavigationScreen() : const LockScreen(),
    );
  }
}
