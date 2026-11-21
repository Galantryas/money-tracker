import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/security/biometric_service.dart';

class AuthState {
  final bool isUnlocked;
  final bool isBiometricEnabled;
  final bool isDeviceSupported;
  final bool hasPin;
  final bool requiresPinSetup;
  final String? errorMessage;

  AuthState({
    required this.isUnlocked,
    required this.isBiometricEnabled,
    required this.isDeviceSupported,
    required this.hasPin,
    this.requiresPinSetup = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isUnlocked,
    bool? isBiometricEnabled,
    bool? isDeviceSupported,
    bool? hasPin,
    bool? requiresPinSetup,
    String? errorMessage,
  }) {
    return AuthState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
      hasPin: hasPin ?? this.hasPin,
      requiresPinSetup: requiresPinSetup ?? this.requiresPinSetup,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final BiometricService _biometricService;
  int _failedPinAttempts = 0;
  DateTime? _pinBlockedUntil;
  final DateTime Function() _now;
  bool _checkingPin = false;

  AuthNotifier(this._biometricService, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(AuthState(
          isUnlocked: false,
          isBiometricEnabled: true,
          isDeviceSupported: false,
          hasPin: false,
        )) {
    init();
  }

  Future<void> init() async {
    final supported = await _biometricService.isDeviceSupported();
    final enabled = await _biometricService.isBiometricEnabled();
    final hasPin = await _biometricService.hasPin();
    if (!mounted) return;

    state = state.copyWith(
      isDeviceSupported: supported,
      isBiometricEnabled: enabled,
      hasPin: hasPin,
    );

    // If biometric security is disabled by user, unlock automatically
    if (!enabled) {
      state = state.copyWith(isUnlocked: true);
    } else {
      // Auto-trigger biometric prompt on startup
      await authenticate();
    }
  }

  Future<bool> authenticate() async {
    if (state.requiresPinSetup) return false;
    state = state.copyWith(errorMessage: null);
    final success = await _biometricService.authenticate();
    if (!mounted) return false;
    if (success) {
      state = state.copyWith(isUnlocked: true);
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Autentikasi sidik jari gagal atau dibatalkan');
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    if (_checkingPin) return false;
    _checkingPin = true;
    try {
      final saved = await _biometricService.loadPinRetryState();
      if (!mounted) return false;
      _failedPinAttempts = saved.failures;
      _pinBlockedUntil = saved.blockedUntil;
      return await _verifyPin(pin);
    } catch (_) {
      if (mounted) state = state.copyWith(errorMessage: 'PIN tidak dapat diperiksa. Silakan coba lagi.');
      return false;
    } finally {
      _checkingPin = false;
    }
  }

  Future<bool> _verifyPin(String pin) async {
    if (_pinBlockedUntil != null && _now().isBefore(_pinBlockedUntil!)) {
      state = state.copyWith(errorMessage: 'Terlalu banyak percobaan. Tunggu 30 detik dan coba lagi.');
      return false;
    }
    if (_pinBlockedUntil != null) {
      _failedPinAttempts = 0;
      _pinBlockedUntil = null;
    }
    final valid = await _biometricService.verifyPin(pin);
    if (valid) {
      final hasSavedPin = await _biometricService.hasPin();
      await _biometricService.savePinRetryState(0, null);
      if (!mounted) return false;
      _failedPinAttempts = 0;
      state = state.copyWith(
        hasPin: hasSavedPin,
        isUnlocked: hasSavedPin,
        requiresPinSetup: !hasSavedPin,
        errorMessage: null,
      );
      return true;
    } else {
      _failedPinAttempts++;
      if (_failedPinAttempts >= 5) {
        _pinBlockedUntil = _now().add(const Duration(seconds: 30));
      }
      await _biometricService.savePinRetryState(_failedPinAttempts, _pinBlockedUntil);
      if (!mounted) return false;
      state = state.copyWith(errorMessage: _pinBlockedUntil == null
          ? 'PIN salah, silakan coba lagi'
          : 'Terlalu banyak percobaan. Tunggu 30 detik dan coba lagi.');
      return false;
    }
  }

  Future<void> completeLegacyPinSetup(String pin) async {
    if (!state.requiresPinSetup ||
        !RegExp(r'^\d{4}$').hasMatch(pin) || pin == '1234') {
      throw ArgumentError('Pilih PIN baru dengan 4 digit selain 1234.');
    }
    await _biometricService.setPin(pin);
    state = state.copyWith(hasPin: true, requiresPinSetup: false, isUnlocked: true);
  }

  Future<void> setPin(String pin) async {
    await _biometricService.setPin(pin);
    state = state.copyWith(hasPin: true);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _biometricService.setBiometricEnabled(enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  void lockApp() {
    if (state.isBiometricEnabled) {
      state = state.copyWith(isUnlocked: false, requiresPinSetup: false);
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(biometricServiceProvider);
  return AuthNotifier(service);
});
