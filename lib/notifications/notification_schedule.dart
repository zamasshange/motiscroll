import 'package:timezone/timezone.dart' as tz;

import 'notification_prefs.dart';

/// Wall-clock time on [date] in [location]. The tz database applies DST
/// for that local date; offsets are never hardcoded.
tz.TZDateTime zonedWallClock({
  required tz.Location location,
  required DateTime date,
  required int hour,
  required int minute,
}) {
  return tz.TZDateTime(
    location,
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  );
}

tz.TZDateTime zonedForSlot({
  required tz.Location location,
  required DateTime date,
  required NotificationSlot slot,
  required NotificationPrefs prefs,
}) {
  final clock = slot == NotificationSlot.morning
      ? prefs.morningClock
      : prefs.eveningClock;
  return zonedWallClock(
    location: location,
    date: date,
    hour: clock.hour,
    minute: clock.minute,
  );
}

bool timezoneChanged(String stored, String current) {
  return stored.isNotEmpty && stored != current;
}

int clampNotificationsPerDay(int value) {
  if (value < 0) return 0;
  if (value > maxNotificationsPerDayHardCap) {
    return maxNotificationsPerDayHardCap;
  }
  return value;
}

bool canScheduleNotifications({
  required bool granted,
  required bool killSwitchOn,
  required bool anySlotEnabled,
}) {
  return granted && killSwitchOn && anySlotEnabled;
}
