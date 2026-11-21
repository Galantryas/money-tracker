import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BalancePrivacyNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _key = 'is_balance_visible';
  late final Future<void> ready;

  BalancePrivacyNotifier() : super(false) {
    ready = _loadState();
  }

  Future<void> _loadState() async {
    try {
      final val = await _storage.read(key: _key);
      if (mounted) state = val == null || val == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    await ready;
    if (!mounted) return;
    state = !state;
    await _storage.write(key: _key, value: state.toString());
  }

  Future<void> setVisible(bool isVisible) async {
    await ready;
    if (!mounted) return;
    state = isVisible;
    await _storage.write(key: _key, value: state.toString());
  }
}

final balancePrivacyProvider =
    StateNotifierProvider<BalancePrivacyNotifier, bool>((ref) {
  return BalancePrivacyNotifier();
});
