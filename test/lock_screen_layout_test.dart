import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/security/biometric_service.dart';
import 'package:money_tracker/providers/auth_provider.dart';
import 'package:money_tracker/views/auth/lock_screen.dart';

class UnavailableBiometrics extends BiometricService {
  @override
  Future<bool> isDeviceSupported() async => false;
  @override
  Future<bool> authenticate({String reason = ''}) async => false;
}

void main() {
  testWidgets('lock screen remains scrollable with large text and PIN controls have labels', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'user_security_pin': '9876'});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      biometricServiceProvider.overrideWithValue(UnavailableBiometrics()),
    ], child: MaterialApp(
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 2), child: child!),
      home: const LockScreen(),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Gunakan PIN Fallback'));
    await tester.tap(find.text('Gunakan PIN Fallback'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Hapus digit PIN'), findsOneWidget);
    expect(find.byTooltip('Gunakan biometrik'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
