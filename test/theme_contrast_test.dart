import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/theme/app_theme.dart';

void main() {
  test('elevated button text has accessible contrast in both themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final style = theme.elevatedButtonTheme.style!;
      final background = style.backgroundColor!.resolve(<MaterialState>{})!;
      final foreground = style.foregroundColor!.resolve(<MaterialState>{})!;
      final a = background.computeLuminance();
      final b = foreground.computeLuminance();
      final ratio = (a > b ? a + 0.05 : b + 0.05) /
          (a > b ? b + 0.05 : a + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });

  test('filled buttons meet normal-text contrast in both themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final style = theme.filledButtonTheme.style!;
      final background = style.backgroundColor!.resolve(<MaterialState>{})!.computeLuminance();
      final foreground = style.foregroundColor!.resolve(<MaterialState>{})!.computeLuminance();
      expect((foreground + 0.05) / (background + 0.05), greaterThanOrEqualTo(4.5));
    }
  });
}
