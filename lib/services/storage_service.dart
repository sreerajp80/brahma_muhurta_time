// File Path: brahma_muhurta_time/lib/services/storage_service.dart
// Author: Sreeraj P
// Created:
// Last Modified: 2025 october 18
// Description: Service to manage storage of saved locations and notification settings.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_location.dart';
import '../services/app_logger.dart';

class StorageService {
  static const String _savedLocationsKey = 'saved_locations';
  static const String _lastUsedLocationKey = 'last_used_location';
  static const String _useLocationModeKey = 'use_location_mode';

  // Location modes
  static const String modeLive = 'live';
  static const String modeSaved = 'saved';

  // New constants for notification management
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastNotificationScheduleDateKey =
      'last_notification_schedule_date';

  /// Save locations to storage
  static Future<void> saveLocations(List<SavedLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = locations.map((loc) => loc.toJson()).toList();
    await prefs.setString(_savedLocationsKey, jsonEncode(locationsJson));
  }

  /// Get all saved locations
  static Future<List<SavedLocation>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsString = prefs.getString(_savedLocationsKey);

    if (locationsString == null || locationsString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> locationsJson = jsonDecode(locationsString);
      return locationsJson.map((json) => SavedLocation.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error loading saved locations', e, 'StorageService');
      return [];
    }
  }

  /// Add a new saved location
  static Future<void> addSavedLocation(SavedLocation location) async {
    final locations = await getSavedLocations();

    // Check if location with same name exists
    final existingIndex = locations.indexWhere(
      (loc) => loc.name.toLowerCase() == location.name.toLowerCase(),
    );

    if (existingIndex != -1) {
      // Update existing location
      locations[existingIndex] = location;
    } else {
      locations.add(location);
    }

    await saveLocations(locations);
  }

  /// Delete a saved location
  static Future<void> deleteSavedLocation(String id) async {
    final locations = await getSavedLocations();
    locations.removeWhere((loc) => loc.id == id);
    await saveLocations(locations);
  }

  /// Set last used location
  static Future<void> setLastUsedLocation(SavedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsedLocationKey, jsonEncode(location.toJson()));
  }

  /// Get last used location
  static Future<SavedLocation?> getLastUsedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final locationString = prefs.getString(_lastUsedLocationKey);

    if (locationString == null || locationString.isEmpty) {
      return null;
    }

    try {
      final locationJson = jsonDecode(locationString);
      return SavedLocation.fromJson(locationJson);
    } catch (e) {
      AppLogger.error('Error loading last used location', e, 'StorageService');
      return null;
    }
  }

  /// Set location mode (live or saved)
  static Future<void> setLocationMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_useLocationModeKey, mode);
  }

  /// Get location mode
  static Future<String> getLocationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_useLocationModeKey) ?? modeLive;
  }

  /// Clear all saved locations
  static Future<void> clearAllLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedLocationsKey);
    await prefs.remove(_lastUsedLocationKey);
  }

  /// Get notifications enabled status
  static Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsEnabledKey) ??
          true; // Default to enabled
    } catch (e) {
      return true; // Default fallback
    }
  }

  /// Set notifications enabled status
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, enabled);
    } catch (e) {
      AppLogger.error(
          'Error saving notifications enabled status', e, 'StorageService');
    }
  }

  /// Get last notification schedule date
  static Future<DateTime?> getLastNotificationScheduleDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastNotificationScheduleDateKey);
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      return null; // Return null if parsing fails
    }
  }

  /// Set last notification schedule date
  static Future<void> setLastNotificationScheduleDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastNotificationScheduleDateKey, date.toIso8601String());
    } catch (e) {
      AppLogger.error(
          'Error saving last notification schedule date', e, 'StorageService');
    }
  }

  /// Clear all notification-related data (useful for debugging)
  static Future<void> clearNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationScheduleDateKey);
      await prefs.remove(_notificationsEnabledKey);
    } catch (e) {
      AppLogger.error('Error clearing notification data', e, 'StorageService');
    }
  }

  /// Get all notification-related settings (for debugging)
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    return {
      'enabled': await getNotificationsEnabled(),
      'lastScheduled': await getLastNotificationScheduleDate(),
    };
  }

  /// Generic method to save a string value
  static Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      AppLogger.debug('Saved string for key: $key', 'StorageService');
    } catch (e) {
      AppLogger.error('Error saving string for key: $key', e, 'StorageService');
    }
  }

  /// Generic method to get a string value
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error(
          'Error getting string for key: $key', e, 'StorageService');
      return null;
    }
  }

  /// Generic method to remove a value
  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      AppLogger.debug('Removed key: $key', 'StorageService');
    } catch (e) {
      AppLogger.error('Error removing key: $key', e, 'StorageService');
    }
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      AppLogger.error('Error checking key: $key', e, 'StorageService');
      return false;
    }
  }
}
