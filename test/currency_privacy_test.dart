import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/currency_formatter.dart';

void main() {
  test('hides amount and sign when privacy mode is enabled', () {
    expect(CurrencyFormatter.privateAmount(12345, isVisible: false, sign: '-'), '••••••');
    expect(CurrencyFormatter.privateAmount(12345, isVisible: true, sign: '-'), '-Rp 12.345');
  });
}
