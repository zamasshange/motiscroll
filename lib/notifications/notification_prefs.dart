import '../data/models.dart';

/// Hard cap. Remote Config may only lower this, never raise it.
const maxNotificationsPerDayHardCap = 2;

const notificationHorizonDays = 14;
const notificationTaperAfterDays = 7;
const notificationWordLimit = 30;
const notifiedRepeatDays = 60;
const notificationAuthorWindowDays = 3;
const maxPendingPlanNotifications = 28;

const defaultMorningTime = '09:30';
const defaultEveningTime = '20:30';

const notificationPlanKey = 'notification_plan_v1';
const notificationNotifiedKey = 'notification_notified_v1';

enum NotificationSlot { morning, evening }

enum QuoteSource { followedFields, all, mood }

class ClockTime {
  const ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;

  String get hhmm {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

ClockTime parseHHmm(String value, {String fallback = defaultMorningTime}) {
  final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value.trim());
  if (match == null) return parseHHmm(fallback, fallback: '09:30');
  return ClockTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
}

QuoteSource quoteSourceFromName(String? name) {
  return switch (name) {
    'all' => QuoteSource.all,
    'mood' => QuoteSource.mood,
    _ => QuoteSource.followedFields,
  };
}

extension QuoteSourceName on QuoteSource {
  String get stored {
    return switch (this) {
      QuoteSource.followedFields => 'followed_fields',
      QuoteSource.all => 'all',
      QuoteSource.mood => 'mood',
    };
  }
}

class NotificationPrefs {
  const NotificationPrefs({
    this.morningEnabled = true,
    this.morningTime = defaultMorningTime,
    this.eveningEnabled = true,
    this.eveningTime = defaultEveningTime,
    this.pausedUntil,
    this.quoteSource = QuoteSource.followedFields,
    this.timeZone = 'UTC',
  });

  final bool morningEnabled;
  final String morningTime;
  final bool eveningEnabled;
  final String eveningTime;
  final String? pausedUntil;
  final QuoteSource quoteSource;
  final String timeZone;

  ClockTime get morningClock =>
      parseHHmm(morningTime, fallback: defaultMorningTime);
  ClockTime get eveningClock =>
      parseHHmm(eveningTime, fallback: defaultEveningTime);

  bool get anyEnabled => morningEnabled || eveningEnabled;

  bool isPausedOn(String date) {
    final until = pausedUntil;
    if (until == null || until.isEmpty) return false;
    return date.compareTo(until) < 0;
  }

  NotificationPrefs copyWith({
    bool? morningEnabled,
    String? morningTime,
    bool? eveningEnabled,
    String? eveningTime,
    String? pausedUntil,
    bool clearPausedUntil = false,
    QuoteSource? quoteSource,
    String? timeZone,
  }) {
    return NotificationPrefs(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningTime: morningTime ?? this.morningTime,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningTime: eveningTime ?? this.eveningTime,
      pausedUntil: clearPausedUntil ? null : (pausedUntil ?? this.pausedUntil),
      quoteSource: quoteSource ?? this.quoteSource,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  Map<String, Object?> toJson() => {
    'morningEnabled': morningEnabled,
    'morningTime': morningClock.hhmm,
    'eveningEnabled': eveningEnabled,
    'eveningTime': eveningClock.hhmm,
    'pausedUntil': pausedUntil,
    'quoteSource': quoteSource.stored,
    'timeZone': timeZone,
  };

  /// Maps the Phase 2 `reminderTime` onto [morningTime].
  factory NotificationPrefs.fromJson(
    Map<String, dynamic>? map, {
    String? legacyReminderTime,
    bool? legacyReminderOn,
  }) {
    final stored = map ?? const <String, dynamic>{};
    final morningTime =
        stored['morningTime'] as String? ??
        legacyReminderTime ??
        defaultMorningTime;
    var morningEnabled = stored['morningEnabled'] as bool? ?? true;
    var eveningEnabled = stored['eveningEnabled'] as bool? ?? true;
    if (stored['morningEnabled'] == null && legacyReminderOn == false) {
      morningEnabled = false;
      eveningEnabled = false;
    }
    return NotificationPrefs(
      morningEnabled: morningEnabled,
      morningTime: parseHHmm(morningTime).hhmm,
      eveningEnabled: eveningEnabled,
      eveningTime: parseHHmm(
        stored['eveningTime'] as String? ?? defaultEveningTime,
        fallback: defaultEveningTime,
      ).hhmm,
      pausedUntil: stored['pausedUntil'] as String?,
      quoteSource: quoteSourceFromName(stored['quoteSource'] as String?),
      timeZone: stored['timeZone'] as String? ?? 'UTC',
    );
  }

  Map<String, Object?> toFirestore(Mood? usualMood) {
    return {
      'timezone': timeZone,
      'morningEnabled': morningEnabled,
      'morningTime': morningClock.hhmm,
      'eveningEnabled': eveningEnabled,
      'eveningTime': eveningClock.hhmm,
      'pausedUntil': pausedUntil,
      'quoteSource': quoteSource.stored,
      'usualMood': usualMood?.name,
      'reminderTime': morningClock.hhmm,
      'reminderLocal': morningEnabled || eveningEnabled,
    };
  }
}

int motiNotificationId(String date, NotificationSlot slot) {
  final compact = date.replaceAll('-', '');
  return int.parse(compact) * 10 + slot.index + 1;
}

List<int> motiNotificationIdRange({required DateTime from, int days = 16}) {
  final ids = <int>[];
  final start = DateTime(from.year, from.month, from.day);
  for (var i = 0; i < days; i++) {
    final date = dayKey(start.add(Duration(days: i)));
    ids.add(motiNotificationId(date, NotificationSlot.morning));
    ids.add(motiNotificationId(date, NotificationSlot.evening));
  }
  return ids;
}
