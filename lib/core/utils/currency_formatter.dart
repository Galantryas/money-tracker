import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(num amount) {
    if (amount >= 1000000000) {
      final val = amount / 1000000000;
      final numStr = val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',');
      return 'Rp $numStr M';
    } else if (amount >= 1000000) {
      final val = amount / 1000000;
      final numStr = val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',');
      return 'Rp $numStr jt';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      final numStr = val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1).replaceAll('.', ',');
      return 'Rp $numStr rb';
    }
    return format(amount);
  }

  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
