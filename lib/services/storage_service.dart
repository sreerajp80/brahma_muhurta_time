// File Path: lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_location.dart';
import '../services/app_logger.dart';

class StorageService {
  static const String _savedLocationsKey = 'saved_locations';
  static const String _lastUsedLocationKey = 'last_used_location';
  static const String _useLocationModeKey = 'use_location_mode';

  // Location modes
  static const String MODE_LIVE = 'live';
  static const String MODE_SAVED = 'saved';

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
    return prefs.getString(_useLocationModeKey) ?? MODE_LIVE;
  }

  /// Clear all saved locations
  static Future<void> clearAllLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedLocationsKey);
    await prefs.remove(_lastUsedLocationKey);
  }
}
