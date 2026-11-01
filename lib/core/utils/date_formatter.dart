import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static String formatWithTime(DateTime date) {
    return formatShort(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(dateOnly).inDays;

    if (diffDays == 0) {
      return 'Hari ini';
    } else if (diffDays == 1) {
      return 'Kemarin';
    } else if (diffDays == -1) {
      return 'Besok';
    } else if (diffDays < 7 && diffDays > 0) {
      return '$diffDays hari lalu';
    } else {
      return formatShort(date);
    }
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }
}
