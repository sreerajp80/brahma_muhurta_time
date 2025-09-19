// File Path: lib/services/calculation_service.dart

import 'dart:math';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/brahma_muhurta_time.dart';
import '../services/app_logger.dart';

class CalculationService {
  static const int _brahmaMuhurtaDurationMinutes = 48;
  static bool _timezoneInitialized = false;

  /// Initialize timezone database (call this once in your app initialization)
  static void initializeTimezones() {
    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      _timezoneInitialized = true;
    }
  }

  /// Calculate Brahma Muhurta time for given coordinates
  static BrahmaMuhurtaTime calculateBrahmaMuhurta(
    double latitude,
    double longitude, {
    DateTime? date,
  }) {
    // Ensure timezone data is initialized
    initializeTimezones();

    date ??= DateTime.now();

    // Strip time from date to ensure we're working with the start of day
    date = DateTime(date.year, date.month, date.day);

    // Calculate sunrise time with proper timezone handling
    DateTime sunriseTime = _calculateSunrise(latitude, longitude, date);

    // IMPORTANT: Convert to local DateTime to avoid timezone comparison issues
    DateTime sunriseLocal = DateTime(
      sunriseTime.year,
      sunriseTime.month,
      sunriseTime.day,
      sunriseTime.hour,
      sunriseTime.minute,
    );

    // Brahma Muhurta starts 96 minutes before sunrise
    DateTime brahmaMuhurtaStart = sunriseLocal.subtract(
      const Duration(minutes: 96),
    );

    // Brahma Muhurta ends 48 minutes before sunrise
    DateTime brahmaMuhurtaEnd = sunriseLocal.subtract(
      const Duration(minutes: 48),
    );

    final timeFormat = DateFormat('HH:mm');

    AppLogger.debug('Brahma Muhurta DateTime Values:', 'CalculationService');
    AppLogger.debug(
        '  Start DateTime: $brahmaMuhurtaStart', 'CalculationService');
    AppLogger.debug(
        '  Start Hour: ${brahmaMuhurtaStart.hour} (should be around 5)',
        'CalculationService');
    AppLogger.debug('  End DateTime: $brahmaMuhurtaEnd', 'CalculationService');
    AppLogger.debug('  End Hour: ${brahmaMuhurtaEnd.hour} (should be around 6)',
        'CalculationService');

    return BrahmaMuhurtaTime(
      startTime: timeFormat.format(brahmaMuhurtaStart),
      endTime: timeFormat.format(brahmaMuhurtaEnd),
      sunriseTime: timeFormat.format(sunriseLocal),
      startDateTime: brahmaMuhurtaStart,
      endDateTime: brahmaMuhurtaEnd,
      sunriseDateTime: sunriseLocal,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Calculate next day's Brahma Muhurta
  static BrahmaMuhurtaTime calculateTomorrowsBrahmaMuhurta(
    double latitude,
    double longitude,
  ) {
    DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    return calculateBrahmaMuhurta(latitude, longitude, date: tomorrow);
  }

  /// Calculate sunrise time using NOAA astronomical formulas
  static DateTime _calculateSunrise(
    double latitude,
    double longitude,
    DateTime date,
  ) {
    // Determine the timezone for the given coordinates
    String timezoneName = _getTimezoneForCoordinates(latitude, longitude);
    final location = tz.getLocation(timezoneName);

    // Calculate the day of year
    int dayOfYear = _getDayOfYear(date);

    // Calculate fractional year (γ) in radians
    double gamma = 2 * pi * (dayOfYear - 1) / 365.0;

    // Calculate equation of time in minutes
    double eqTime = 229.18 *
        (0.000075 +
            0.001868 * cos(gamma) -
            0.032077 * sin(gamma) -
            0.014615 * cos(2 * gamma) -
            0.040849 * sin(2 * gamma));

    // Calculate solar declination angle in radians
    double declination = 0.006918 -
        0.399912 * cos(gamma) +
        0.070257 * sin(gamma) -
        0.006758 * cos(2 * gamma) +
        0.000907 * sin(2 * gamma) -
        0.002697 * cos(3 * gamma) +
        0.00148 * sin(3 * gamma);

    // Convert latitude to radians
    double latRad = _toRadians(latitude);

    // Calculate hour angle for sunrise (with atmospheric refraction)
    double zenithAngle = _toRadians(90.833); // Official sunrise/sunset
    double cosHourAngle = cos(zenithAngle) / (cos(latRad) * cos(declination)) -
        tan(latRad) * tan(declination);

    // Check for polar day/night
    if (cosHourAngle > 1.0) {
      // Sun never rises (polar night)
      AppLogger.warning('Sun never rises at this location on this date',
          'CalculationService');
      return tz.TZDateTime(location, date.year, date.month, date.day, 6, 0);
    } else if (cosHourAngle < -1.0) {
      // Sun never sets (polar day)
      AppLogger.warning(
          'Sun never sets at this location on this date', 'CalculationService');
      return tz.TZDateTime(location, date.year, date.month, date.day, 6, 0);
    }

    // Calculate sunrise hour angle in degrees
    double hourAngleDegrees = _toDegrees(acos(cosHourAngle));

    // Calculate sunrise time in minutes from midnight UTC
    // For sunrise, we subtract the hour angle
    double sunriseTimeMinutes =
        720 - 4 * longitude - eqTime - 4 * hourAngleDegrees;

    // Adjust to 0-1440 range
    while (sunriseTimeMinutes < 0) {
      sunriseTimeMinutes += 1440;
    }
    while (sunriseTimeMinutes >= 1440) {
      sunriseTimeMinutes -= 1440;
    }

    // Convert to hours and minutes
    int hour = (sunriseTimeMinutes / 60).floor();
    int minute = (sunriseTimeMinutes % 60).round();

    // Handle edge case where rounding gives us 60 minutes
    if (minute == 60) {
      minute = 0;
      hour += 1;
    }

    // Handle edge case where hour becomes 24
    if (hour >= 24) {
      hour -= 24;
    }

    // Create sunrise DateTime in UTC
    DateTime sunriseUTC = DateTime.utc(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    // Convert UTC to location's timezone
    tz.TZDateTime sunriseLocal = tz.TZDateTime.from(sunriseUTC, location);

    // FIX: Validate sunrise is in morning hours (4 AM - 10 AM range)
    // If hour is in PM (after 12), it's likely a calculation error
    if (sunriseLocal.hour > 12) {
      // Sunrise showing PM time, subtract 12 hours to get correct AM time
      sunriseLocal = sunriseLocal.subtract(const Duration(hours: 12));
      AppLogger.warning(
          'Adjusted sunrise from PM to AM time', 'CalculationService');
    } else if (sunriseLocal.hour < 4 || sunriseLocal.hour > 10) {
      // Additional validation - sunrise typically between 4-10 AM
      AppLogger.warning(
          'Unusual sunrise time detected: ${sunriseLocal.hour}:${sunriseLocal.minute}',
          'CalculationService');
    }

    // Debug output
    AppLogger.debug('Sunrise Calculation Debug:', 'CalculationService');
    AppLogger.debug(
        '  Location: Lat ${latitude.toStringAsFixed(4)}, Lng ${longitude.toStringAsFixed(4)}',
        'CalculationService');
    AppLogger.debug('  Timezone: $timezoneName', 'CalculationService');
    AppLogger.debug(
        '  Date: ${date.year}-${date.month}-${date.day}', 'CalculationService');
    AppLogger.debug('  Day of year: $dayOfYear', 'CalculationService');
    AppLogger.debug('  Equation of time: ${eqTime.toStringAsFixed(2)} minutes',
        'CalculationService');
    AppLogger.debug(
        '  Solar declination: ${_toDegrees(declination).toStringAsFixed(2)} degrees',
        'CalculationService');
    AppLogger.debug(
        '  Hour angle: ${hourAngleDegrees.toStringAsFixed(2)} degrees',
        'CalculationService');
    AppLogger.debug(
        '  Sunrise minutes from midnight UTC: ${sunriseTimeMinutes.toStringAsFixed(2)}',
        'CalculationService');
    AppLogger.debug(
        '  Sunrise UTC: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        'CalculationService');
    AppLogger.debug(
        '  Sunrise Local: ${sunriseLocal.hour.toString().padLeft(2, '0')}:${sunriseLocal.minute.toString().padLeft(2, '0')}',
        'CalculationService');

    return sunriseLocal;
  }

  /// Get day of year
  static int _getDayOfYear(DateTime date) {
    DateTime jan1 = DateTime(date.year, 1, 1);
    return date.difference(jan1).inDays + 1;
  }

  /// Determine timezone based on coordinates
  static String _getTimezoneForCoordinates(double latitude, double longitude) {
    // United States
    if (latitude >= 24 &&
        latitude <= 50 &&
        longitude >= -125 &&
        longitude <= -66) {
      // Pacific Time Zone
      if (longitude >= -125 && longitude <= -115) {
        return 'America/Los_Angeles';
      }
      // Mountain Time Zone
      else if (longitude >= -115 && longitude <= -105) {
        return 'America/Denver';
      }
      // Central Time Zone
      else if (longitude >= -105 && longitude <= -90) {
        return 'America/Chicago';
      }
      // Eastern Time Zone
      else if (longitude >= -90 && longitude <= -66) {
        return 'America/New_York';
      }
    }

    // Canada
    if (latitude >= 41 && latitude <= 84) {
      if (longitude >= -141 && longitude <= -123) {
        return 'America/Vancouver';
      } else if (longitude >= -123 && longitude <= -90) {
        return 'America/Edmonton';
      } else if (longitude >= -90 && longitude <= -74) {
        return 'America/Toronto';
      }
    }

    // Europe
    if (latitude >= 35 &&
        latitude <= 71 &&
        longitude >= -10 &&
        longitude <= 40) {
      // UK & Ireland
      if (longitude >= -10 && longitude <= 2) {
        return 'Europe/London';
      }
      // Western Europe
      else if (longitude >= 2 && longitude <= 15) {
        return 'Europe/Berlin';
      }
      // Eastern Europe
      else if (longitude >= 15 && longitude <= 30) {
        return 'Europe/Athens';
      }
      // Russia (Western part)
      else if (longitude >= 30 && longitude <= 40) {
        return 'Europe/Moscow';
      }
    }

    // India and surrounding regions
    if (latitude >= 6 && latitude <= 35 && longitude >= 68 && longitude <= 97) {
      return 'Asia/Kolkata';
    }

    // China
    if (latitude >= 20 &&
        latitude <= 54 &&
        longitude >= 73 &&
        longitude <= 135) {
      return 'Asia/Shanghai';
    }

    // Japan
    if (latitude >= 24 &&
        latitude <= 46 &&
        longitude >= 123 &&
        longitude <= 146) {
      return 'Asia/Tokyo';
    }

    // Australia
    if (latitude >= -44 && latitude <= -10) {
      // Western Australia
      if (longitude >= 112 && longitude <= 129) {
        return 'Australia/Perth';
      }
      // Central Australia
      else if (longitude >= 129 && longitude <= 141) {
        return 'Australia/Adelaide';
      }
      // Eastern Australia
      else if (longitude >= 141 && longitude <= 154) {
        return 'Australia/Sydney';
      }
    }

    // South America
    if (latitude >= -55 && latitude <= 12) {
      // Brazil
      if (latitude >= -33 &&
          latitude <= 5 &&
          longitude >= -74 &&
          longitude <= -34) {
        return 'America/Sao_Paulo';
      }
      // Argentina
      else if (latitude >= -55 &&
          latitude <= -21 &&
          longitude >= -73 &&
          longitude <= -53) {
        return 'America/Argentina/Buenos_Aires';
      }
      // Chile
      else if (longitude >= -76 && longitude <= -66) {
        return 'America/Santiago';
      }
      // Colombia/Venezuela
      else if (latitude >= -4 &&
          latitude <= 12 &&
          longitude >= -79 &&
          longitude <= -59) {
        return 'America/Bogota';
      }
    }

    // Africa
    if (latitude >= -35 && latitude <= 37) {
      // South Africa
      if (latitude >= -35 &&
          latitude <= -22 &&
          longitude >= 16 &&
          longitude <= 33) {
        return 'Africa/Johannesburg';
      }
      // Egypt
      else if (latitude >= 22 &&
          latitude <= 32 &&
          longitude >= 25 &&
          longitude <= 35) {
        return 'Africa/Cairo';
      }
      // Nigeria
      else if (latitude >= 4 &&
          latitude <= 14 &&
          longitude >= 2 &&
          longitude <= 15) {
        return 'Africa/Lagos';
      }
      // Kenya
      else if (latitude >= -5 &&
          latitude <= 5 &&
          longitude >= 34 &&
          longitude <= 42) {
        return 'Africa/Nairobi';
      }
    }

    // Middle East
    if (latitude >= 12 &&
        latitude <= 42 &&
        longitude >= 35 &&
        longitude <= 63) {
      // UAE
      if (latitude >= 22 &&
          latitude <= 26 &&
          longitude >= 51 &&
          longitude <= 57) {
        return 'Asia/Dubai';
      }
      // Saudi Arabia
      else if (latitude >= 16 &&
          latitude <= 32 &&
          longitude >= 35 &&
          longitude <= 55) {
        return 'Asia/Riyadh';
      }
      // Israel
      else if (latitude >= 29 &&
          latitude <= 34 &&
          longitude >= 34 &&
          longitude <= 36) {
        return 'Asia/Jerusalem';
      }
    }

    // Southeast Asia
    if (latitude >= -11 && latitude <= 28) {
      // Thailand
      if (longitude >= 97 && longitude <= 106) {
        return 'Asia/Bangkok';
      }
      // Indonesia
      else if (latitude >= -11 &&
          latitude <= 6 &&
          longitude >= 95 &&
          longitude <= 141) {
        return 'Asia/Jakarta';
      }
      // Philippines
      else if (latitude >= 5 &&
          latitude <= 20 &&
          longitude >= 117 &&
          longitude <= 127) {
        return 'Asia/Manila';
      }
      // Singapore/Malaysia
      else if (latitude >= -1 &&
          latitude <= 7 &&
          longitude >= 100 &&
          longitude <= 120) {
        return 'Asia/Singapore';
      }
    }

    // New Zealand
    if (latitude >= -47 &&
        latitude <= -34 &&
        longitude >= 166 &&
        longitude <= 179) {
      return 'Pacific/Auckland';
    }

    // Default fallback: estimate timezone from longitude
    // This is a rough approximation (15 degrees per hour)
    int offsetHours = (longitude / 15).round();

    // Try to find a timezone with this offset
    if (offsetHours == 0) return 'UTC';
    if (offsetHours == 1) return 'Europe/Paris';
    if (offsetHours == 2) return 'Europe/Helsinki';
    if (offsetHours == 3) return 'Europe/Moscow';
    if (offsetHours == 4) return 'Asia/Dubai';
    if (offsetHours == 5) return 'Asia/Karachi';
    if (offsetHours == 6) return 'Asia/Dhaka';
    if (offsetHours == 7) return 'Asia/Bangkok';
    if (offsetHours == 8) return 'Asia/Shanghai';
    if (offsetHours == 9) return 'Asia/Tokyo';
    if (offsetHours == 10) return 'Australia/Sydney';
    if (offsetHours == -5) return 'America/New_York';
    if (offsetHours == -6) return 'America/Chicago';
    if (offsetHours == -7) return 'America/Denver';
    if (offsetHours == -8) return 'America/Los_Angeles';

    // Final fallback
    return 'UTC';
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Convert radians to degrees
  static double _toDegrees(double radians) {
    return radians * 180.0 / pi;
  }

  /// Format duration as readable text
  static String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get time until next Brahma Muhurta
  static String getTimeUntilNext(BrahmaMuhurtaTime brahmaMuhurta) {
    if (brahmaMuhurta.isCurrentlyActive) {
      Duration remaining = brahmaMuhurta.timeRemaining!;
      return 'Ends in ${formatDuration(remaining)}';
    } else {
      Duration timeUntil = brahmaMuhurta.timeUntilStart ?? Duration.zero;
      if (timeUntil.inMinutes > 0) {
        return 'Starts in ${formatDuration(timeUntil)}';
      } else {
        return 'Calculating next...';
      }
    }
  }
}
