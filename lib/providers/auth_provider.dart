import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/security/biometric_service.dart';

class AuthState {
  final bool isUnlocked;
  final bool isBiometricEnabled;
  final bool isDeviceSupported;
  final bool hasPin;
  final String? errorMessage;

  AuthState({
    required this.isUnlocked,
    required this.isBiometricEnabled,
    required this.isDeviceSupported,
    required this.hasPin,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isUnlocked,
    bool? isBiometricEnabled,
    bool? isDeviceSupported,
    bool? hasPin,
    String? errorMessage,
  }) {
    return AuthState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
      hasPin: hasPin ?? this.hasPin,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final BiometricService _biometricService;

  AuthNotifier(this._biometricService)
      : super(AuthState(
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
    state = state.copyWith(errorMessage: null);
    final success = await _biometricService.authenticate();
    if (success) {
      state = state.copyWith(isUnlocked: true);
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Autentikasi sidik jari gagal atau dibatalkan');
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    final valid = await _biometricService.verifyPin(pin);
    if (valid) {
      state = state.copyWith(isUnlocked: true, errorMessage: null);
      return true;
    } else {
      state = state.copyWith(errorMessage: 'PIN salah, silakan coba lagi');
      return false;
    }
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
      state = state.copyWith(isUnlocked: false);
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
