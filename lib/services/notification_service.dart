// File Path: brahma_muhurta_time/lib/services/notification_service.dart
// Author: Sreeraj P
// Last Modified: 2025 October 18
// Description: Service to manage local notifications with custom ringtone support

import 'dart:ui';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/brahma_muhurta_time.dart';
import '../services/app_logger.dart';
import '../services/calculation_service.dart';
import '../services/storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Channel configuration
  String _channelId = 'brahma_muhurta_channel_v0';
  static const String _channelIdPrefix = 'brahma_muhurta_channel_v';
  static const String _channelName = 'Brahma Muhurta';
  static const String _channelDescription =
      'Notifications for Brahma Muhurta times';
  static const String _channelVersionKey = 'notification_channel_version';

  // Notification IDs
  static const int _baseReminderIdStart = 1000;
  static const int _baseStartIdStart = 2000;
  static const int _baseAfterStartIdStart = 3000;
  static const int _maxDaysAdvance = 30;

  // Custom ringtone storage
  static const String _customRingtoneKey = 'custom_notification_ringtone';
  static const String _customRingtoneNameKey =
      'custom_notification_ringtone_name';
  static const String _notificationSoundFileName = 'notification_sound';
  String? _customRingtonePath;
  String? _customRingtoneName;
  String? _packageName;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    await _loadPackageName();
    await _loadCustomRingtone();
    await _loadChannelVersion();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
  }

  Future<void> _loadPackageName() async {
    try {
      _packageName = 'in.sreerajp.brahma_muhurta_time';
      AppLogger.debug('Package name: $_packageName', 'NotificationService');
    } catch (e) {
      AppLogger.error('Error loading package name', e, 'NotificationService');
    }
  }

  Future<void> _loadChannelVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentVersion = prefs.getInt(_channelVersionKey) ?? 0;
      _channelId = '$_channelIdPrefix$currentVersion';
      AppLogger.debug(
          'Loaded channel version: $currentVersion', 'NotificationService');
    } catch (e) {
      AppLogger.error(
          'Error loading channel version', e, 'NotificationService');
      _channelId = '${_channelIdPrefix}0';
    }
  }

  Future<void> _loadCustomRingtone() async {
    try {
      _customRingtonePath = await StorageService.getString(_customRingtoneKey);
      _customRingtoneName =
          await StorageService.getString(_customRingtoneNameKey);

      if (_customRingtonePath != null && _customRingtonePath!.isNotEmpty) {
        final file = File(_customRingtonePath!);
        if (!await file.exists()) {
          AppLogger.warning(
              'Saved ringtone file not found, resetting to default',
              'NotificationService');
          _customRingtonePath = null;
          _customRingtoneName = null;
          await StorageService.remove(_customRingtoneKey);
          await StorageService.remove(_customRingtoneNameKey);
        } else {
          AppLogger.info(
              'Loaded custom ringtone: $_customRingtoneName ($_customRingtonePath)',
              'NotificationService');
        }
      }
    } catch (e) {
      AppLogger.error(
          'Error loading custom ringtone', e, 'NotificationService');
      _customRingtonePath = null;
      _customRingtoneName = null;
    }
  }

  /// Convert file path to content URI for FileProvider
  String _getContentUri(String filePath) {
    // FIXED: Use correct FileProvider path mapping
    final fileName = path.basename(filePath);
    return 'content://$_packageName.fileprovider/app_sounds/$fileName';
  }

  /// Set custom notification ringtone from external file path
  Future<bool> setCustomRingtone(String? externalFilePath,
      {String? fileName}) async {
    try {
      if (externalFilePath == null || externalFilePath.isEmpty) {
        await _removeCustomRingtone();
        await _recreateNotificationChannel();
        return true;
      }

      final sourceFile = File(externalFilePath);
      if (!await sourceFile.exists()) {
        AppLogger.error(
            'Source audio file not found', null, 'NotificationService');
        return false;
      }

      final extension = path.extension(externalFilePath).toLowerCase();
      if (!_isValidAudioFormat(extension)) {
        AppLogger.error(
            'Invalid audio format: $extension. Use MP3, OGG, or WAV',
            null,
            'NotificationService');
        return false;
      }

      // FIXED: Use getApplicationSupportDirectory() which maps to Context.getFilesDir()
      // This is what FileProvider's <files-path> expects
      final appDir = await getApplicationSupportDirectory();
      final soundsDir = Directory('${appDir.path}/sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final internalFileName = '$_notificationSoundFileName$extension';
      final internalFilePath = '${soundsDir.path}/$internalFileName';

      AppLogger.info(
          'Copying audio file from $externalFilePath to $internalFilePath',
          'NotificationService');

      final internalFile = File(internalFilePath);
      if (await internalFile.exists()) {
        await internalFile.delete();
      }

      await sourceFile.copy(internalFilePath);

      if (!await internalFile.exists()) {
        AppLogger.error(
            'Failed to copy audio file', null, 'NotificationService');
        return false;
      }

      final fileSize = await internalFile.length();
      AppLogger.info('Audio file copied successfully. Size: $fileSize bytes',
          'NotificationService');

      // Verify file is readable
      try {
        await internalFile.readAsBytes();
        AppLogger.info(
            'Audio file verified as readable', 'NotificationService');
      } catch (e) {
        AppLogger.error('Audio file not readable', e, 'NotificationService');
        return false;
      }

      _customRingtonePath = internalFilePath;
      _customRingtoneName = fileName ?? path.basename(externalFilePath);

      await StorageService.saveString(_customRingtoneKey, internalFilePath);
      await StorageService.saveString(
          _customRingtoneNameKey, _customRingtoneName!);

      await _recreateNotificationChannel();

      AppLogger.info(
          'Custom ringtone set: $_customRingtoneName', 'NotificationService');
      return true;
    } catch (e) {
      AppLogger.error(
          'Error setting custom ringtone', e, 'NotificationService');
      return false;
    }
  }

  bool _isValidAudioFormat(String extension) {
    // Android prefers OGG and MP3 for notification sounds
    const validFormats = ['.mp3', '.ogg', '.wav'];
    return validFormats.contains(extension.toLowerCase());
  }

  Future<void> _removeCustomRingtone() async {
    try {
      if (_customRingtonePath != null) {
        final file = File(_customRingtonePath!);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info('Deleted custom ringtone file', 'NotificationService');
        }
      }

      _customRingtonePath = null;
      _customRingtoneName = null;
      await StorageService.remove(_customRingtoneKey);
      await StorageService.remove(_customRingtoneNameKey);

      AppLogger.info(
          'Custom ringtone removed, using default', 'NotificationService');
    } catch (e) {
      AppLogger.error(
          'Error removing custom ringtone', e, 'NotificationService');
    }
  }

  Future<void> _recreateNotificationChannel() async {
    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final prefs = await SharedPreferences.getInstance();
        int currentVersion = prefs.getInt(_channelVersionKey) ?? 0;
        currentVersion++;
        await prefs.setInt(_channelVersionKey, currentVersion);

        _channelId = '$_channelIdPrefix$currentVersion';

        AndroidNotificationSound? sound;
        if (_customRingtonePath != null && _customRingtonePath!.isNotEmpty) {
          final file = File(_customRingtonePath!);
          if (await file.exists()) {
            final contentUri = _getContentUri(_customRingtonePath!);
            sound = UriAndroidNotificationSound(contentUri);
            AppLogger.info('Using custom sound with content URI: $contentUri',
                'NotificationService');
          } else {
            AppLogger.warning(
                'Custom sound file not found, falling back to default',
                'NotificationService');
            sound = null;
          }
        }

        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance:
              Importance.max, // Changed to max for better sound playback
          enableVibration: true,
          playSound: true,
          sound: sound,
        );

        await androidPlugin.createNotificationChannel(channel);

        AppLogger.info(
            'Notification channel recreated: $_channelId (v$currentVersion) with ${sound != null ? "custom" : "default"} sound',
            'NotificationService');
      }
    } catch (e) {
      AppLogger.error(
          'Error recreating notification channel', e, 'NotificationService');
    }
  }

  String? getCustomRingtoneName() => _customRingtoneName;
  String? getCustomRingtonePath() => _customRingtonePath;
  bool hasCustomRingtone() =>
      _customRingtonePath != null && _customRingtonePath!.isNotEmpty;

  Future<void> _createNotificationChannel() async {
    AndroidNotificationSound? sound;
    if (_customRingtonePath != null && _customRingtonePath!.isNotEmpty) {
      final file = File(_customRingtonePath!);
      if (await file.exists()) {
        final contentUri = _getContentUri(_customRingtonePath!);
        sound = UriAndroidNotificationSound(contentUri);
        AppLogger.debug(
            'Channel sound URI: $contentUri', 'NotificationService');
      }
    }

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max, // Changed to max
      enableVibration: true,
      playSound: true,
      sound: sound,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    AppLogger.debug(
        'Notification channel created: $_channelId with ${sound != null ? "custom" : "default"} sound',
        'NotificationService');
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return true;
  }

  Future<void> scheduleNotificationsAdvanced({
    required double latitude,
    required double longitude,
    int daysInAdvance = 7,
  }) async {
    await cancelAllNotifications();

    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      AppLogger.warning(
          'Notification permission denied', 'NotificationService');
      return;
    }

    try {
      final today = DateTime.now();
      int notificationsScheduled = 0;

      for (int dayOffset = 0;
          dayOffset < daysInAdvance && dayOffset < _maxDaysAdvance;
          dayOffset++) {
        final targetDate = today.add(Duration(days: dayOffset));

        final brahmaMuhurta = CalculationService.calculateBrahmaMuhurta(
          latitude,
          longitude,
          date: targetDate,
        );

        final scheduled =
            await _scheduleNotificationsForDay(brahmaMuhurta, dayOffset);
        notificationsScheduled += scheduled;
      }

      AppLogger.info(
          'Scheduled $notificationsScheduled notifications for $daysInAdvance days',
          'NotificationService');
    } catch (e) {
      AppLogger.error(
          'Error scheduling advanced notifications', e, 'NotificationService');
    }
  }

  Future<int> _scheduleNotificationsForDay(
      BrahmaMuhurtaTime brahmaMuhurta, int dayOffset) async {
    int scheduled = 0;

    try {
      final reminderNotificationId = _baseReminderIdStart + dayOffset;
      final startNotificationId = _baseStartIdStart + dayOffset;
      final afterStartNotificationId = _baseAfterStartIdStart + dayOffset;

      DateTime reminderTime = brahmaMuhurta.startDateTime.subtract(
        const Duration(minutes: 15),
      );

      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: reminderNotificationId,
          title: 'Brahma Muhurta Reminder',
          body:
              'Brahma Muhurta starts in 15 minutes at ${brahmaMuhurta.startTime}',
          scheduledDate: reminderTime,
        );
        scheduled++;
      }

      if (brahmaMuhurta.startDateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: startNotificationId,
          title: 'Brahma Muhurta Started',
          body: 'Brahma Muhurta is now active until ${brahmaMuhurta.endTime}',
          scheduledDate: brahmaMuhurta.startDateTime,
        );
        scheduled++;
      }

      DateTime afterStartTime = brahmaMuhurta.startDateTime.add(
        const Duration(minutes: 15),
      );

      if (afterStartTime.isAfter(DateTime.now()) &&
          afterStartTime.isBefore(brahmaMuhurta.endDateTime)) {
        await _scheduleNotification(
          id: afterStartNotificationId,
          title: 'Brahma Muhurta Active',
          body:
              'Brahma Muhurta is in progress. Ends at ${brahmaMuhurta.endTime}',
          scheduledDate: afterStartTime,
        );
        scheduled++;
      }
    } catch (e) {
      AppLogger.error('Error scheduling notifications for day $dayOffset', e,
          'NotificationService');
    }

    return scheduled;
  }

  Future<void> scheduleNotifications(BrahmaMuhurtaTime brahmaMuhurta) async {
    await cancelAllNotifications();
    bool hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      await _scheduleNotificationsForDay(brahmaMuhurta, 0);
      AppLogger.info('Notifications scheduled for ${brahmaMuhurta.startTime}',
          'NotificationService');
    } catch (e) {
      AppLogger.error(
          'Error scheduling notifications', e, 'NotificationService');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    AndroidNotificationSound? sound;
    if (_customRingtonePath != null && _customRingtonePath!.isNotEmpty) {
      final file = File(_customRingtonePath!);
      if (await file.exists()) {
        final contentUri = _getContentUri(_customRingtonePath!);
        sound = UriAndroidNotificationSound(contentUri);
      }
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max, // Changed to max
      priority: Priority.max, // Changed to max
      enableVibration: true,
      playSound: true,
      sound: sound,
      styleInformation: BigTextStyleInformation(''),
      enableLights: true,
      ledColor: Color(0xFF6B4E71),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _customRingtoneName,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    AndroidNotificationSound? sound;
    if (_customRingtonePath != null && _customRingtonePath!.isNotEmpty) {
      final file = File(_customRingtonePath!);
      if (await file.exists()) {
        final contentUri = _getContentUri(_customRingtonePath!);
        sound = UriAndroidNotificationSound(contentUri);
        AppLogger.info(
            'Instant notification using: $contentUri', 'NotificationService');
      }
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      sound: sound,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _customRingtoneName,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.info('All notifications cancelled', 'NotificationService');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    final pending = await getPendingNotifications();
    final reminderCount = pending
        .where((n) =>
            n.id >= _baseReminderIdStart &&
            n.id < _baseReminderIdStart + _maxDaysAdvance)
        .length;
    final startCount = pending
        .where((n) =>
            n.id >= _baseStartIdStart &&
            n.id < _baseStartIdStart + _maxDaysAdvance)
        .length;
    final afterStartCount = pending
        .where((n) =>
            n.id >= _baseAfterStartIdStart &&
            n.id < _baseAfterStartIdStart + _maxDaysAdvance)
        .length;

    final prefs = await SharedPreferences.getInstance();
    final channelVersion = prefs.getInt(_channelVersionKey) ?? 0;

    return {
      'total': pending.length,
      'reminders': reminderCount,
      'starts': startCount,
      'afterStarts': afterStartCount,
      'nextNotification': pending.isNotEmpty ? pending.first.id : null,
      'hasCustomRingtone': hasCustomRingtone(),
      'customRingtoneName': _customRingtoneName,
      'customRingtonePath': _customRingtonePath,
      'channelId': _channelId,
      'channelVersion': channelVersion,
    };
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.debug(
        'Notification tapped: ${response.payload}', 'NotificationService');
  }

  Future<void> testNotification() async {
    await showInstantNotification(
      title: 'Test Notification',
      body:
          'Great! Your notifications are working properly. You will receive 3 alerts: 15 min before, at start, and 15 min after Brahma Muhurta begins.',
    );
    AppLogger.info('Test notification triggered', 'NotificationService');
  }
}
