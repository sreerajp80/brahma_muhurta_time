// lib/constants/app_info.dart

class AppInfo {
  static const String appName = 'Brahma Muhurta Calculator';
  static const String appVersion = '1.0.0';
  static const String conceptAndDesign = 'Sreeraj P';
  static const String aiUsed = 'Claude Sonnet 4';
  static const String ide = 'Visual Studio Code';

  // Build date can be set during CI/CD or manually updated
  static String get buildDate {
    // You can replace this with actual build date from your CI/CD
    return '19th September 2025';
  }

  // Additional app information
  static const String packageName = 'com.brahma_muhurta';
  static const String minSdkVersion = '24';
  static const String targetSdkVersion = '34';
}
