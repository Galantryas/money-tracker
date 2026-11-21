import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'currency_formatter.dart';

String financialValueDisplay(AsyncValue<dynamic> source, num value,
    {required bool isVisible, bool compact = false}) {
  if (source.hasError) return 'Tidak tersedia';
  if (source.isLoading || source.valueOrNull == null) return 'Memuat...';
  if (!isVisible) return '••••••';
  return compact ? CurrencyFormatter.formatCompact(value) : CurrencyFormatter.format(value);
}
