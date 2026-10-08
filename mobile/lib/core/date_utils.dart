// lib/core/date_utils.dart
//
// Date formatting and helper functions.
// Formats dates using the intl package as "08 Oct 2026" for display
// and "yyyy-MM-dd" for the REST API.

import 'package:intl/intl.dart';
import '../models/task.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');

  /// Formats a DateTime for user display, e.g. "08 Oct 2026".
  /// Returns "—" if [date] is null.
  static String formatDisplay(DateTime? date) {
    if (date == null) return '—';
    return _displayFormat.format(date);
  }

  /// Formats a date range, e.g. "08 Oct 2026 – 15 Oct 2026".
  static String formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '—';
    if (start != null && end == null) return 'From ${formatDisplay(start)}';
    if (start == null && end != null) return 'Until ${formatDisplay(end)}';
    return '${formatDisplay(start)} – ${formatDisplay(end)}';
  }

  /// Formats a DateTime for the backend API: "yyyy-MM-dd".
  static String? formatApi(DateTime? date) {
    if (date == null) return null;
    return _apiFormat.format(date);
  }

  /// Determines whether a task is overdue (past due and not yet completed).
  static bool isOverdue(DateTime? dueDate, TaskStatus status) {
    if (dueDate == null || status == TaskStatus.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }
}
