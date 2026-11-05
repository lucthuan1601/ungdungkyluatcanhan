import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');

  /// Returns date formatted as 'YYYY-MM-DD' (standard ISO format for SQLite storage)
  static String toIsoDateString(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Parses 'YYYY-MM-DD' string to a normalized DateTime (at 00:00:00)
  static DateTime parseIsoDateString(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return dateOnly(DateTime.parse(dateStr));
  }

  /// Normalizes DateTime to 00:00:00 to avoid time-of-day discrepancy
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Format date for UI display: "dd/MM/yyyy"
  static String formatDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Format month & year: "Tháng MM/yyyy"
  static String formatMonthYear(DateTime date) {
    return 'Tháng ${_monthYearFormat.format(date)}';
  }

  /// Format for date strip / header: e.g. "Thứ Năm, 05/11"
  static String formatHeaderDate(DateTime date) {
    final weekday = AppConstants.weekdayNames[date.weekday] ?? '';
    return '$weekday, ${DateFormat('dd/MM').format(date)}';
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if two dates represent the same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get 7 days of the week (Monday = 1 through Sunday = 7) containing referenceDate
  static List<DateTime> getWeekDays(DateTime referenceDate) {
    final normalized = dateOnly(referenceDate);
    final monday = normalized.subtract(Duration(days: normalized.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  /// Returns all calendar dates for the month of referenceDate
  static List<DateTime> getDaysInMonth(DateTime referenceDate) {
    final lastDay = DateTime(referenceDate.year, referenceDate.month + 1, 0);
    final totalDays = lastDay.day;
    return List.generate(
      totalDays,
      (index) => DateTime(referenceDate.year, referenceDate.month, index + 1),
    );
  }

  /// Parses 'HH:mm' string to TimeOfDay
  static TimeOfDay? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Formats TimeOfDay to 'HH:mm'
  static String formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Returns localized short weekday name (e.g. 'T2', 'CN')
  static String getWeekdayShortName(int weekday) {
    return AppConstants.weekdayShortNames[weekday] ?? '';
  }

  /// Returns localized full weekday name (e.g. 'Thứ Hai', 'Chủ Nhật')
  static String getWeekdayFullName(int weekday) {
    return AppConstants.weekdayNames[weekday] ?? '';
  }

  /// Format days-of-week string ('1,2,3,4,5,6,7') into human readable description
  static String formatDaysOfWeekDescription(String daysOfWeek) {
    if (daysOfWeek.isEmpty) return 'Chưa chọn ngày';
    final days = daysOfWeek
        .split(',')
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toList()
      ..sort();

    if (days.length == 7) {
      return 'Hàng ngày';
    }
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Thứ 2 - Thứ 6';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Cuối tuần';
    }

    return days.map((d) => getWeekdayShortName(d)).join(', ');
  }
}
