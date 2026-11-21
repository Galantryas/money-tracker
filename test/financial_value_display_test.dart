import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/utils/financial_value_display.dart';

void main() {
  test('loading and failed amounts are not displayed as zero', () {
    expect(financialValueDisplay(const AsyncValue<int>.loading(), 0, isVisible: true), 'Memuat...');
    expect(financialValueDisplay(AsyncValue<int>.error(Exception(), StackTrace.empty), 0, isVisible: true), 'Tidak tersedia');
    expect(financialValueDisplay(const AsyncValue<int>.data(0), 0, isVisible: true), 'Rp 0');
    expect(financialValueDisplay(const AsyncValue<int>.data(0), 0, isVisible: false), '••••••');
  });
}
