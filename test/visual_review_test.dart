import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/core/theme/app_theme.dart';
import 'package:money_tracker/providers/category_budget_provider.dart';
import 'package:money_tracker/views/budgets/category_budget_screen.dart';
import 'package:money_tracker/views/reports/date_range_report_screen.dart';
import 'package:money_tracker/views/stats/stats_screen.dart';
import 'support/finance_fixtures.dart';

// Opt-in captures use fixture data only. No installed app database is opened.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final output = Platform.environment['MONEY_TRACKER_REVIEW_DIR'];
  final font = Platform.environment['MONEY_TRACKER_REVIEW_FONT'];
  final iconFont = Platform.environment['MONEY_TRACKER_REVIEW_ICON_FONT'];
  final screens = <String, Widget Function()>{
    'budgets': () => CategoryBudgetScreen(month: DateTime.now()),
    'reports': () => const DateRangeReportScreen(),
    'statistics': () => const StatsScreen(),
  };
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    if (font != null) {
      final bytes = await File(font).readAsBytes();
      await (FontLoader('Review')
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
      await (FontLoader('Roboto')
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
    if (iconFont != null) {
      final bytes = await File(iconFont).readAsBytes();
      await (FontLoader('MaterialIcons')
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });
  for (final dark in [false, true]) {
    for (final large in [false, true]) {
      for (final screen in screens.keys) {
        testWidgets(
            '$screen ${dark ? "dark" : "light"} ${large ? "large" : "normal"}',
            (tester) async {
          FlutterSecureStorage.setMockInitialValues(
              {'is_balance_visible': 'true'});
          tester.view.physicalSize = Size(large ? 320 : 390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
          await tester.pumpWidget(ProviderScope(
              overrides: [
                ...financeOverrides(),
                categoryBudgetLimitsProvider
                    .overrideWith((ref) async => {'Tempat Tinggal': 1000000}),
              ],
              child: MaterialApp(
                theme: theme.copyWith(
                  chipTheme: theme.chipTheme.copyWith(
                      labelStyle: theme.chipTheme.labelStyle?.copyWith(
                          fontFamily: font == null ? null : 'Review')),
                  textTheme: theme.textTheme
                      .apply(fontFamily: font == null ? null : 'Review'),
                  appBarTheme: theme.appBarTheme.copyWith(
                      titleTextStyle: theme.appBarTheme.titleTextStyle
                          ?.copyWith(
                              fontFamily: font == null ? null : 'Review')),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaleFactor: large ? 2 : 1),
                  child: child!,
                ),
                home: RepaintBoundary(
                    key: const ValueKey('capture'), child: screens[screen]!()),
              )));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('capture')));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
                    '$output/${screen}_${dark ? "dark" : "light"}_${large ? "large" : "normal"}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }, skip: output == null);
      }
    }
  }
}
