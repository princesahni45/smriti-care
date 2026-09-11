// lib/core/services/notification_service.dart
//
// FIX: Sync caregiver reminder changes to linked patient - notification service
// Handles local Android notifications for patient reminders.
// Schedules exact local notifications with stable IDs derived from reminderId.
// Automatically cancels and reschedules when caregiver edits or toggles reminders.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/caregiver_models.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'smriti_care_reminders';
  static const String channelName = 'Patient Reminders';
  static const String channelDescription =
      'Scheduled reminders for medication, hydration, and daily care routines';

  /// Initialize local notifications plugin and setup channels
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const androidChannel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          );
          await androidPlugin.createNotificationChannel(androidChannel);
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Init note: $e');
    } finally {
      _isInitialized = true;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Reminder tapped: ${response.payload}');
  }

  /// Convert reminderId to a deterministic positive integer notification ID
  int getNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 100000;
  }

  /// Parse time string like '08:00 PM', '10:30 AM', '14:00'
  Map<String, int> parseTime(String timeStr) {
    var str = timeStr.trim().toUpperCase();
    var isPm = str.contains('PM');
    var isAm = str.contains('AM');
    str = str.replaceAll('AM', '').replaceAll('PM', '').trim();

    final parts = str.split(':');
    var hour = int.tryParse(parts[0]) ?? 9;
    var minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    return {'hour': hour.clamp(0, 23), 'minute': minute.clamp(0, 59)};
  }

  /// Calculate the next scheduled DateTime for the given hour and minute
  DateTime getNextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedule a notification for a caregiver reminder
  // FIX: Sync caregiver reminder changes to linked patient
  Future<void> scheduleReminder(CaregiverReminder reminder) async {
    await init();
    final notifId = getNotificationId(reminder.id);

    // If reminder is disabled, cancel any active notification and return
    if (!reminder.enabled) {
      await cancelReminder(reminder.id);
      return;
    }

    try {
      final timeParts = parseTime(reminder.scheduledTime);
      final hour = timeParts['hour']!;
      final minute = timeParts['minute']!;
      final targetDt = getNextInstanceOfTime(hour, minute);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'SmritiCare Reminder',
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const notifDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(sound: 'default'),
      );

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final tzScheduled = tz.TZDateTime.from(targetDt, tz.local);

        if (reminder.repeat == 'daily') {
          await _plugin.zonedSchedule(
            id: notifId,
            title: '⏰ ${reminder.title}',
            body: reminder.message.isNotEmpty
                ? reminder.message
                : 'Scheduled for ${reminder.scheduledTime}',
            scheduledDate: tzScheduled,
            notificationDetails: notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: reminder.id,
          );
        } else {
          await _plugin.zonedSchedule(
            id: notifId,
            title: '⏰ ${reminder.title}',
            body: reminder.message.isNotEmpty
                ? reminder.message
                : 'Scheduled for ${reminder.scheduledTime}',
            scheduledDate: tzScheduled,
            notificationDetails: notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: reminder.id,
          );
        }
      } else {
        // Desktop / test fallback: show immediately or log
        debugPrint(
            '[NotificationService] Scheduled reminder "${reminder.title}" at $targetDt');
      }
    } catch (e) {
      debugPrint('[NotificationService] Schedule error for ${reminder.id}: $e');
    }
  }

  /// Cancel scheduled notification for a reminder
  // FIX: Sync caregiver reminder changes to linked patient
  Future<void> cancelReminder(String reminderId) async {
    await init();
    final notifId = getNotificationId(reminderId);
    try {
      await _plugin.cancel(id: notifId);
      debugPrint('[NotificationService] Canceled notification for $reminderId');
    } catch (e) {
      debugPrint('[NotificationService] Cancel error for $reminderId: $e');
    }
  }

  /// Reschedule all active reminders for the patient
  // FIX: Sync caregiver reminder changes to linked patient
  Future<void> rescheduleAll(List<CaregiverReminder> reminders) async {
    await init();
    try {
      await _plugin.cancelAll();
      for (final r in reminders) {
        if (r.enabled) {
          await scheduleReminder(r);
        }
      }
      debugPrint(
          '[NotificationService] Rescheduled ${reminders.where((r) => r.enabled).length} active reminders');
    } catch (e) {
      debugPrint('[NotificationService] rescheduleAll note: $e');
    }
  }
}
