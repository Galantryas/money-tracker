import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/providers/balance_privacy_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts hidden until the saved privacy setting is loaded', () async {
    FlutterSecureStorage.setMockInitialValues({'is_balance_visible': 'false'});
    final notifier = BalancePrivacyNotifier();
    expect(notifier.state, isFalse);
    await notifier.ready;
    expect(notifier.state, isFalse);
    notifier.dispose();
  });

  test('a new installation defaults to visible after loading', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final notifier = BalancePrivacyNotifier();
    await notifier.ready;
    expect(notifier.state, isTrue);
    notifier.dispose();
  });
}
