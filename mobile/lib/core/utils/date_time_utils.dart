import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static final DateFormat _ymdFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('EEE, d MMM');
  static final DateFormat _shortDayFormat = DateFormat('E');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Format as YYYY-MM-DD for backend API payloads
  static String formatYmd(DateTime date) => _ymdFormat.format(date);

  /// Parse YYYY-MM-DD from backend API payloads
  static DateTime? parseYmd(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return _ymdFormat.parse(dateStr.trim());
    } catch (_) {
      return DateTime.tryParse(dateStr);
    }
  }

  /// Month & Year (e.g. "October 2026")
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Day & Month (e.g. "Sat, 4 Oct")
  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// Short Day Name (e.g. "Sat")
  static String formatShortDay(DateTime date) => _shortDayFormat.format(date);

  /// Full Date (e.g. "Saturday, October 4, 2026")
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);

  /// Time formatted as HH:mm (e.g. "14:30")
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Clean time string (e.g. "07:00:00" -> "07:00")
  static String cleanTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return timeStr;
  }

  /// Normalizes a DateTime to midnight (00:00:00) for exact calendar day equality
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Check whether two dates refer to the exact same calendar day
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
