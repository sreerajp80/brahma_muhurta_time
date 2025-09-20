// File Path: lib/services/notification_service.dart

import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../models/brahma_muhurta_time.dart';
import '../services/app_logger.dart';
import '../services/calculation_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'brahma_muhurta_channel';
  static const String _channelName = 'Brahma Muhurta';
  static const String _channelDescription =
      'Notifications for Brahma Muhurta times';

  // Notification IDs - using ranges to avoid conflicts
  static const int _baseReminderIdStart = 1000; // 1000-1999 for reminders
  static const int _baseStartIdStart =
      2000; // 2000-2999 for start notifications
  static const int _maxDaysAdvance = 30; // Schedule up to 30 days in advance

  Future<void> initialize() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
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

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    // For Android 13+ (API level 33+), request notification permission
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    // For iOS, request specific permissions
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

  /// Schedule notifications for multiple days in advance
  Future<void> scheduleNotificationsAdvanced({
    required double latitude,
    required double longitude,
    int daysInAdvance = 7,
  }) async {
    // Clear existing notifications
    await cancelAllNotifications();

    // Check if we have permission
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      AppLogger.warning(
          'Notification permission denied', 'NotificationService');
      return;
    }

    try {
      final today = DateTime.now();
      int notificationsScheduled = 0;

      // Schedule for multiple days
      for (int dayOffset = 0;
          dayOffset < daysInAdvance && dayOffset < _maxDaysAdvance;
          dayOffset++) {
        final targetDate = today.add(Duration(days: dayOffset));

        // Calculate Brahma Muhurta for this date
        final brahmaMuhurta = CalculationService.calculateBrahmaMuhurta(
          latitude,
          longitude,
          date: targetDate,
        );

        // Schedule notifications for this day
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

  /// Schedule notifications for a specific day
  Future<int> _scheduleNotificationsForDay(
      BrahmaMuhurtaTime brahmaMuhurta, int dayOffset) async {
    int scheduled = 0;

    try {
      // Generate unique IDs for this day
      final reminderNotificationId = _baseReminderIdStart + dayOffset;
      final startNotificationId = _baseStartIdStart + dayOffset;

      // Schedule reminder notification (15 minutes before)
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

      // Schedule start notification
      if (brahmaMuhurta.startDateTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: startNotificationId,
          title: 'Brahma Muhurta Started',
          body: 'Brahma Muhurta is now active until ${brahmaMuhurta.endTime}',
          scheduledDate: brahmaMuhurta.startDateTime,
        );
        scheduled++;
      }
    } catch (e) {
      AppLogger.error('Error scheduling notifications for day $dayOffset', e,
          'NotificationService');
    }

    return scheduled;
  }

  /// Legacy method for single day scheduling (backwards compatibility)
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
      // Add wake screen capability
      enableLights: true,
      ledColor: Color(0xFF6B4E71),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
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

  /// Get status of scheduled notifications
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

    return {
      'total': pending.length,
      'reminders': reminderCount,
      'starts': startCount,
      'nextNotification': pending.isNotEmpty ? pending.first.id : null,
    };
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.debug(
        'Notification tapped: ${response.payload}', 'NotificationService');
    // Handle notification tap - could open specific screen or perform action
  }

  Future<void> testNotification() async {
    await showInstantNotification(
      title: 'Test Notification',
      body:
          'Great! Your notifications are working properly. You will receive alerts before and during Brahma Muhurta.',
    );
    AppLogger.info('Test notification triggered', 'NotificationService');
  }
}
