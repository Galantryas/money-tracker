import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:money_tracker/core/security/biometric_service.dart';
import 'package:money_tracker/providers/auth_provider.dart';

class FakeBiometricService extends BiometricService {
  String? pin;

  FakeBiometricService(this.pin);

  @override
  Future<bool> isDeviceSupported() async => false;
  @override
  Future<bool> isBiometricEnabled() async => true;
  @override
  Future<bool> hasPin() async => pin != null;
  @override
  Future<bool> authenticate({String reason = ''}) async => false;
  @override
  Future<bool> verifyPin(String enteredPin) async => enteredPin == (pin ?? '1234');
  @override
  Future<void> setPin(String value) async => pin = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('legacy fallback requires a new PIN before unlocking', () async {
    final service = FakeBiometricService(null);
    final auth = AuthNotifier(service);
    await auth.init();
    expect(await auth.unlockWithPin('1234'), isTrue);
    expect(auth.state.isUnlocked, isFalse);
    expect(auth.state.requiresPinSetup, isTrue);
    await auth.completeLegacyPinSetup('4826');
    expect(service.pin, '4826');
    expect(auth.state.isUnlocked, isTrue);
    expect(auth.state.requiresPinSetup, isFalse);
    auth.dispose();
  });

  test('existing PIN unlocks without replacing it', () async {
    final service = FakeBiometricService('9876');
    final auth = AuthNotifier(service);
    await auth.init();
    expect(await auth.unlockWithPin('9876'), isTrue);
    expect(auth.state.isUnlocked, isTrue);
    expect(auth.state.requiresPinSetup, isFalse);
    expect(service.pin, '9876');
    auth.dispose();
  });

  test('a saved PIN is not treated as legacy during initialization', () async {
    final service = FakeBiometricService('9876');
    final auth = AuthNotifier(service);
    expect(await auth.unlockWithPin('9876'), isTrue);
    expect(auth.state.isUnlocked, isTrue);
    expect(auth.state.requiresPinSetup, isFalse);
    auth.dispose();
  });

  test('legacy setup rejects the default PIN and remains locked', () async {
    final auth = AuthNotifier(FakeBiometricService(null));
    await auth.init();
    await auth.unlockWithPin('1234');
    await expectLater(auth.completeLegacyPinSetup('1234'), throwsArgumentError);
    expect(auth.state.isUnlocked, isFalse);
    expect(auth.state.requiresPinSetup, isTrue);
    auth.dispose();
  });

  test('temporarily blocks PIN verification after repeated failures', () async {
    final service = FakeBiometricService('9876');
    final auth = AuthNotifier(service);
    await auth.init();
    for (var i = 0; i < 5; i++) {
      expect(await auth.unlockWithPin('0000'), isFalse);
    }
    expect(await auth.unlockWithPin('9876'), isFalse);
    expect(auth.state.isUnlocked, isFalse);
    auth.dispose();
  });

  test('PIN retry deadline survives restarting the notifier and expires', () async {
    var now = DateTime(2026, 11, 14, 12);
    final service = FakeBiometricService('9876');
    final first = AuthNotifier(service, now: () => now);
    await first.init();
    for (var i = 0; i < 5; i++) {
      await first.unlockWithPin('0000');
    }
    first.dispose();
    final restarted = AuthNotifier(service, now: () => now);
    await restarted.init();
    expect(await restarted.unlockWithPin('9876'), isFalse);
    expect(restarted.state.isUnlocked, isFalse);
    now = now.add(const Duration(seconds: 31));
    expect(await restarted.unlockWithPin('9876'), isTrue);
    expect(restarted.state.isUnlocked, isTrue);
    restarted.dispose();
  });
}
