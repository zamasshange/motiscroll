import '../notifications/notification_service.dart';

/// Phase 2 8:00 repeating reminder. Kept so older imports compile; no-ops.
const reminderId = legacyReminderId;

Future<bool> scheduleDailyReminder() async => false;

Future<void> cancelDailyReminder() {
  return NotificationService.instance.cancelAllScheduled();
}
