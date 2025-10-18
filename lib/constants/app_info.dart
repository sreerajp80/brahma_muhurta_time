// File: brahma_muhurta_time/lib/constants/app_info.dart
// Author: Sreeraj P
// Created:
// Last Modified: 2025 october 18
// Description: Contains application information constants.

class AppInfo {
  static const String appName = 'Brahma Muhurta Calculator';
  static const String appVersion = '1.5.3';
  static const String conceptAndDesign = 'Sreeraj P';
  static const String aiUsed = 'Claude Sonnet 4';
  static const String ide = 'Visual Studio Code';

  // Build date can be set during CI/CD or manually updated
  static String get buildDate {
    // You can replace this with actual build date from your CI/CD
    return '20th September 2025';
  }

  // Additional app information
  static const String packageName = 'com.brahma_muhurta';
  static const String minSdkVersion = '24';
  static const String targetSdkVersion = '34';
}
