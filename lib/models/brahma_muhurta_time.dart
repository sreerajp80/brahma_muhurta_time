class BrahmaMuhurtaTime {
  final String startTime;
  final String endTime;
  final String sunriseTime;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final DateTime sunriseDateTime;
  final double latitude;
  final double longitude;

  const BrahmaMuhurtaTime({
    required this.startTime,
    required this.endTime,
    required this.sunriseTime,
    required this.startDateTime,
    required this.endDateTime,
    required this.sunriseDateTime,
    required this.latitude,
    required this.longitude,
  });

  /// Duration of Brahma Muhurta in minutes (always 96 minutes)
  int get durationInMinutes => 96;

  /// Check if current time is within Brahma Muhurta period
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  /// Time remaining until Brahma Muhurta starts (if not started yet)
  Duration? get timeUntilStart {
    final now = DateTime.now();

    // Create comparable DateTime objects without timezone info
    final nowLocal =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final startLocal = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
      startDateTime.hour,
      startDateTime.minute,
    );

    // If we're on the same day and before start time
    if (nowLocal.year == startLocal.year &&
        nowLocal.month == startLocal.month &&
        nowLocal.day == startLocal.day &&
        nowLocal.isBefore(startLocal)) {
      return startLocal.difference(nowLocal);
    }

    // If current time is after end time on the same day, return null
    // This will trigger "Time has passed for today" message
    return null;
  }

  /// Time remaining in current Brahma Muhurta (if currently active)
  Duration? get timeRemaining {
    final now = DateTime.now();
    if (isCurrentlyActive) {
      return endDateTime.difference(now);
    }
    return null;
  }

  @override
  String toString() {
    return 'BrahmaMuhurtaTime(start: $startTime, end: $endTime, sunrise: $sunriseTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrahmaMuhurtaTime &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.sunriseTime == sunriseTime &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(
      startTime,
      endTime,
      sunriseTime,
      latitude,
      longitude,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LocationData(lat: ${latitude.toStringAsFixed(4)}, lng: ${longitude.toStringAsFixed(4)})';
  }

  String get coordinates {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
