import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/providers/gemini_provider.dart';

void main() {
  test('empty loaded data remains a valid input', () {
    expect(requireFinancialData(const AsyncValue<List<int>>.data([])), isEmpty);
  });

  test('loading and failed data are not treated as empty', () {
    expect(() => requireFinancialData(const AsyncValue<List<int>>.loading()), throwsException);
    expect(() => requireFinancialData(AsyncValue<List<int>>.error(Exception('db'), StackTrace.empty)), throwsException);
  });
}
