import 'package:intl/intl.dart';

class AppDateUtils {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Restituisce "Oggi", "Ieri" o "17 Ottobre"
  static String formatDayHeader(DateTime date) {
    if (isToday(date)) return 'Oggi';
    if (isYesterday(date)) return 'Ieri';
    return DateFormat('d MMMM', 'it_IT').format(date);
  }

  /// Restituisce l'ora formattata, es. "12:45"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Restituisce "Oggi, 12:45" o "Ieri, 20:30" o "15 Ott, 18:00"
  static String formatQuickDate(DateTime date) {
    final time = formatTime(date);
    if (isToday(date)) return 'Oggi, $time';
    if (isYesterday(date)) return 'Ieri, $time';
    return '${DateFormat('d MMM', 'it_IT').format(date)}, $time';
  }

  /// Quanti giorni mancano alla fine del mese (incluso oggi)
  static int daysRemainingInMonth(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    return (lastDay - date.day + 1).clamp(1, 31);
  }

  /// Nome del mese corrente (es. Ottobre 2026)
  static String formatCurrentMonth(DateTime date) {
    return DateFormat('MMMM yyyy', 'it_IT').format(date);
  }
}
