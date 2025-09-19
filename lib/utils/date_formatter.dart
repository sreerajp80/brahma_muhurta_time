// File Path: lib/utils/date_formatter.dart

import 'package:intl/intl.dart';

/// Utility class for formatting dates and timestamps
class DateFormatter {
  /// Formats a timestamp into a relative time string (e.g., "2m ago", "3h ago")
  /// or a formatted date string for older timestamps.
  ///
  /// [timestamp] - The DateTime to format
  /// [includeTime] - Whether to include time in the date format for older timestamps
  static String formatTimestamp(DateTime timestamp,
      {bool includeTime = false}) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      if (includeTime) {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    }
  }

  /// Formats a timestamp into a relative time string with more detail
  /// (e.g., "2 minutes ago", "3 hours ago", "Yesterday at 3:45 PM")
  static String formatTimestampVerbose(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return difference.inSeconds == 1
          ? 'Just now'
          : '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  /// Formats a date in a standard format (e.g., "January 15, 2024")
  static String formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  /// Formats a date in short format (e.g., "Jan 15, 2024")
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Formats a time in 12-hour format (e.g., "3:45 PM")
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Formats a date and time (e.g., "January 15, 2024 3:45 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMMM dd, yyyy h:mm a').format(dateTime);
  }

  /// Returns a relative day label (Today, Tomorrow, Yesterday) or day name
  static String getRelativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final inputDate = DateTime(date.year, date.month, date.day);

    if (inputDate == today) {
      return 'Today';
    } else if (inputDate == tomorrow) {
      return 'Tomorrow';
    } else if (inputDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE').format(date);
    }
  }

  /// Checks if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Gets a duration string from a Duration object (e.g., "2h 30m")
  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Less than a minute';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return '${days}d';
    }
  }
}
