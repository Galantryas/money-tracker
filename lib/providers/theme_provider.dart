import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _key = 'user_theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final val = await _storage.read(key: _key);
    if (val == 'light') {
      state = ThemeMode.light;
    } else if (val == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
