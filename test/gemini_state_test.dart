import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/providers/gemini_provider.dart';

void main() {
  test('removing a key clears it from the in-memory state', () {
    const configured = GeminiState(apiKey: 'secret', isConfigured: true);
    final removed = configured.copyWith(clearApiKey: true, isConfigured: false);
    expect(removed.apiKey, isNull);
    expect(removed.isConfigured, isFalse);
  });
}
