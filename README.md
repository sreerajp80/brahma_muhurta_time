# Brahma Muhurta Flutter App

A Flutter app that calculates Brahma Muhurta times based on your current location. Brahma Muhurta is considered the most auspicious time for spiritual practices, occurring 96 minutes before sunrise.

## Features

- 🌅 **Accurate Calculations**: Uses astronomical formulas to calculate precise sunrise and Brahma Muhurta times
- 📍 **Location-Based**: Automatically gets your location to provide accurate timings
- 🔔 **Smart Notifications**: Reminds you 15 minutes before and when Brahma Muhurta starts
- 🎨 **Beautiful UI**: Modern Material 3 design with smooth animations
- ⏰ **Real-Time Status**: Shows current status and time remaining
- 🔄 **Auto-Refresh**: Easy refresh functionality to update location and timings

## Screenshots

*Add screenshots here when available*

## Installation

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for mobile development

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd brahma_muhurta
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Platform-specific setup**

   **Android:**
   - Ensure your `android/app/src/main/AndroidManifest.xml` includes the location and notification permissions (already configured)
   - Set minimum SDK version to 24 in `android/app/build.gradle`

   **iOS:**
   - Add location and notification permissions to `ios/Runner/Info.plist` (see the provided Info.plist additions)
   - Set minimum iOS deployment target to 11.0

4. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

- `geolocator` - Location services
- `permission_handler` - Permission management
- `flutter_local_notifications` - Local notifications
- `timezone` - Timezone handling
- `provider` - State management
- `intl` - Date/time formatting

## Architecture

The app follows a clean architecture pattern with:

- **Models**: Data classes for Brahma Muhurta time and location data
- **Services**: Business logic for location, calculations, and notifications
- **Providers**: State management using Provider pattern
- **Widgets**: Reusable UI components
- **Screens**: Main application screens

### Key Components

1. **CalculationService**: Handles astronomical calculations for sunrise and Brahma Muhurta times
2. **LocationService**: Manages location permissions and GPS functionality
3. **NotificationService**: Handles scheduling and displaying notifications
4. **BrahmaMuhurtaProvider**: Main state management for the app

## Permissions Required

### Android
- `ACCESS_FINE_LOCATION` - For precise location
- `ACCESS_COARSE_LOCATION` - For approximate location
- `POST_NOTIFICATIONS` - For showing notifications
- `SCHEDULE_EXACT_ALARM` - For precise alarm scheduling
- `WAKE_LOCK` - To wake device for notifications
- `RECEIVE_BOOT_COMPLETED` - To reschedule notifications after reboot

### iOS
- `NSLocationWhenInUseUsageDescription` - Location access
- Background modes for notifications

## How It Works

1. **Location Detection**: App requests location permission and gets current coordinates
2. **Sunrise Calculation**: Uses astronomical formulas to calculate precise sunrise time
3. **Brahma Muhurta Calculation**: Calculates 96 minutes before sunrise
4. **Notification Scheduling**: Sets up notifications for reminder and start times
5. **Real-time Updates**: Shows current status and remaining time

## Astronomical Calculations

The app uses precise astronomical calculations including:
- Solar declination based on day of year
- Equation of time corrections
- Hour angle calculations
- Atmospheric refraction considerations

## Customization

### Changing Duration
Currently set to 96 minutes. To modify, update the constant in `services/calculation_service.dart`:
```dart
static const int _brahmaMuhurtaDurationMinutes = 96;
```

### Notification Timing
To change the reminder time (currently 15 minutes before), modify in `services/notification_service.dart`:
```dart
DateTime reminderTime = brahmaMuhurta.startDateTime.subtract(
  const Duration(minutes: 15), // Change this value
);
```

## Troubleshooting

### Location Issues
- Ensure location services are enabled on device
- Check app permissions in device settings
- Make sure GPS has a clear view of the sky

### Notification Issues
- Enable notification permissions for the app
- Check device's Do Not Disturb settings
- For Android 12+, ensure exact alarm permission is granted

### Calculation Accuracy
- Results may vary slightly based on local terrain and atmospheric conditions
- The app uses standard astronomical calculations which are accurate for most purposes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Astronomical calculation formulas based on standard solar position algorithms
- UI design inspired by Material 3 guidelines
- Thanks to the Flutter community for excellent packages

## Version History

- **1.0.0**: Initial release with basic functionality
  - Location-based Brahma Muhurta calculation
  - Notification system
  - Material 3 UI design
  - Real-time status updates

---

For support or questions, please open an issue on the repository.