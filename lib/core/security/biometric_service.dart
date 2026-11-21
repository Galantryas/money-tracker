import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserPin = 'user_security_pin';
  static const String _keyPinRetry = 'pin_retry_state_v1';

  Future<({int failures, DateTime? blockedUntil})> loadPinRetryState() async {
    final raw = await _storage.read(key: _keyPinRetry);
    if (raw == null) return (failures: 0, blockedUntil: null);
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      return (
        failures: (value['failures'] as int).clamp(0, 5),
        blockedUntil: value['blockedUntil'] == null ? null : DateTime.parse(value['blockedUntil'] as String),
      );
    } on FormatException {
      return (failures: 0, blockedUntil: null);
    } on TypeError {
      return (failures: 0, blockedUntil: null);
    }
  }

  Future<void> savePinRetryState(int failures, DateTime? blockedUntil) async {
    await _storage.write(key: _keyPinRetry, value: jsonEncode({
      'failures': failures, 'blockedUntil': blockedUntil?.toIso8601String(),
    }));
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({String reason = 'Pindai sidik jari untuk membuka Money Tracker'}) async {
    try {
      final isSupported = await isDeviceSupported();
      final canCheck = await canCheckBiometrics();

      if (!isSupported && !canCheck) {
        return false;
      }

      final isMobile = Platform.isAndroid || Platform.isIOS;
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: isMobile,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    // Default to true if not set yet, or false if user explicitly turned it off
    return val == null || val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _keyUserPin);
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await _storage.read(key: _keyUserPin);
    if (savedPin == null) {
      // Default fallback PIN is '1234' for quick testing if not set
      return enteredPin == '1234';
    }
    return savedPin == enteredPin;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _keyUserPin, value: pin);
  }
}
