// File Path: lib/providers/brahma_muhurta_provider.dart

import 'package:flutter/material.dart';
import '../models/brahma_muhurta_time.dart';
import '../models/saved_location.dart';
import '../services/location_service.dart';
import '../services/calculation_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/app_logger.dart';

class BrahmaMuhurtaProvider extends ChangeNotifier {
  BrahmaMuhurtaTime? _brahmaMuhurta;
  LocationData? _currentLocation;
  SavedLocation? _selectedSavedLocation;
  List<SavedLocation> _savedLocations = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _notificationsEnabled = true;
  DateTime _selectedDate = DateTime.now();
  bool _usingLiveLocation = false;

  // Getters
  BrahmaMuhurtaTime? get brahmaMuhurta => _brahmaMuhurta;
  LocationData? get currentLocation => _currentLocation;
  SavedLocation? get selectedSavedLocation => _selectedSavedLocation;
  List<SavedLocation> get savedLocations => _savedLocations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get notificationsEnabled => _notificationsEnabled;
  DateTime get selectedDate => _selectedDate;
  bool get usingLiveLocation => _usingLiveLocation;

  bool get hasLocation =>
      _currentLocation != null || _selectedSavedLocation != null;

  LocationData? get location => _currentLocation;

  // Location Service
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  /// Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);

    // Load saved locations
    await loadSavedLocations();

    // Check last used mode and location
    final mode = await StorageService.getLocationMode();
    final lastUsed = await StorageService.getLastUsedLocation();

    if (mode == StorageService.MODE_SAVED && lastUsed != null) {
      // Use last saved location
      await selectSavedLocation(lastUsed);
    } else if (_savedLocations.isEmpty || mode == StorageService.MODE_LIVE) {
      // Use live location if no saved locations or mode is live
      await useLiveLocation();
    } else if (_savedLocations.isNotEmpty) {
      // Use the first saved location as default
      await selectSavedLocation(_savedLocations.first);
    }

    _setLoading(false);
  }

  /// Load saved locations from storage
  Future<void> loadSavedLocations() async {
    _savedLocations = await StorageService.getSavedLocations();
    notifyListeners();
  }

  /// Use live GPS location
  Future<void> useLiveLocation() async {
    try {
      _setLoading(true);
      _clearError();
      _usingLiveLocation = true;
      _selectedSavedLocation = null;

      // Check permissions first
      bool hasPermission = await _locationService.checkAndRequestPermissions();
      if (!hasPermission) {
        _setError(
            'Location permission denied. Please enable location permissions.');
        return;
      }

      // Check if location service is enabled
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable GPS.');
        // Try to open location settings
        await _locationService.openLocationSettings();
        return;
      }

      // Get current location
      LocationData? locationData = await _locationService.getCurrentLocation();
      if (locationData == null) {
        _setError('Unable to get location. Please check GPS settings.');
        return;
      }

      _currentLocation = locationData;
      await StorageService.setLocationMode(StorageService.MODE_LIVE);

      // Calculate Brahma Muhurta  for selected date
      await _calculateBrahmaMuhurtaForDate();
    } catch (e) {
      _setError('Error getting location: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Use a saved location
  Future<void> selectSavedLocation(SavedLocation location) async {
    _selectedSavedLocation = location;
    _currentLocation = LocationData(
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: DateTime.now(),
    );
    _usingLiveLocation = false;

    await StorageService.setLastUsedLocation(location);
    await StorageService.setLocationMode(StorageService.MODE_SAVED);

    await _calculateBrahmaMuhurtaForDate();
  }

  /// Save current location with a name
  Future<void> saveCurrentLocation(String name) async {
    if (_currentLocation == null) return;

    final savedLocation = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      createdAt: DateTime.now(),
    );

    await StorageService.addSavedLocation(savedLocation);
    await loadSavedLocations();
  }

  /// Save a manually entered location
  Future<void> saveManualLocation(
      String name, double latitude, double longitude) async {
    final savedLocation = SavedLocation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    await StorageService.addSavedLocation(savedLocation);
    await loadSavedLocations();

    // Optionally, automatically select the newly added location
    await selectSavedLocation(savedLocation);
  }

  /// Delete a saved location
  Future<void> deleteSavedLocation(String id) async {
    await StorageService.deleteSavedLocation(id);
    await loadSavedLocations();

    // If deleted location was selected, switch to live location
    if (_selectedSavedLocation?.id == id) {
      await useLiveLocation();
    }
  }

  /// Refresh location (only for live location)
  Future<void> refreshLocation() async {
    if (_usingLiveLocation) {
      await useLiveLocation();
    } else {
      // Just recalculate with current saved location
      await _calculateBrahmaMuhurtaForDate();
    }
  }

  /// Change selected date and recalculate
  Future<void> changeSelectedDate(DateTime date) async {
    _selectedDate = date;
    await _calculateBrahmaMuhurtaForDate();
  }

  /// Calculate Brahma Muhurta for selected date
  Future<void> _calculateBrahmaMuhurtaForDate() async {
    if (_currentLocation == null) return;

    try {
      _brahmaMuhurta = CalculationService.calculateBrahmaMuhurta(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        date: _selectedDate,
      );

      // Only schedule notifications if it's today or future
      if (_notificationsEnabled &&
          _brahmaMuhurta != null &&
          DateUtils.isSameDay(_selectedDate, DateTime.now())) {
        await _scheduleNotifications();
      }

      notifyListeners();
    } catch (e) {
      _setError('Error calculating Brahma Muhurta: ${e.toString()}');
    }
  }

  /// Schedule notifications  for Brahma Muhurta
  Future<void> _scheduleNotifications() async {
    if (_brahmaMuhurta == null) return;

    try {
      await _notificationService.scheduleNotifications(_brahmaMuhurta!);
    } catch (e) {
      AppLogger.error(
          'Error scheduling notifications', e, 'BrahmaMuhurtaProvider');
      // Don't show error to user as this is not critical
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;

    if (_notificationsEnabled &&
        _brahmaMuhurta != null &&
        DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      await _scheduleNotifications();
    } else if (!_notificationsEnabled) {
      await _notificationService.cancelAllNotifications();
    }

    notifyListeners();
  }

  /// Get tomorrow's Brahma Muhurta
  BrahmaMuhurtaTime? getTomorrowsBrahmaMuhurta() {
    if (_currentLocation == null) return null;

    return CalculationService.calculateTomorrowsBrahmaMuhurta(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
    );
  }

  /// Check location permissions
  Future<bool> hasLocationPermission() async {
    return await _locationService.checkAndRequestPermissions();
  }

  /// Get time until next
  String getTimeUntilNext() {
    if (_brahmaMuhurta == null) return '';
    return CalculationService.getTimeUntilNext(_brahmaMuhurta!);
  }

  /// Check if currently active
  bool get isCurrentlyActive {
    if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      return false;
    }
    return _brahmaMuhurta?.isCurrentlyActive ?? false;
  }

  bool get isToday => DateUtils.isSameDay(_selectedDate, DateTime.now());

  String get currentStatus {
    if (_brahmaMuhurta == null) return 'No data available';

    if (isCurrentlyActive) {
      return 'Active now';
    } else if (isToday) {
      return getTimeUntilNext();
    } else {
      return 'Session time: ${_brahmaMuhurta!.startTime} - ${_brahmaMuhurta!.endTime}';
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
