// lib/services/notifications/local_notification_service.dart
//
// Notification service interface for scheduling and firing medication/routine alerts.

abstract class LocalNotificationService {
  Future<void> init();
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}
