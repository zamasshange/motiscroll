import '../data/models.dart';
import 'notification_prefs.dart';
import 'notification_schedule.dart';
import 'notification_text.dart';

int notificationWordCount(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
}

class PlannedNotification {
  const PlannedNotification({
    required this.date,
    required this.slot,
    required this.itemId,
    required this.text,
    required this.authorName,
    required this.title,
    required this.body,
    required this.payload,
    required this.hour,
    required this.minute,
    this.status = 'scheduled',
    this.imageUrl,
  });

  final String date;
  final NotificationSlot slot;
  final String itemId;
  final String text;
  final String authorName;
  final String title;
  final String body;
  final String payload;
  final int hour;
  final int minute;
  final String status;
  final String? imageUrl;

  int get id => motiNotificationId(date, slot);

  String get channelId =>
      slot == NotificationSlot.morning ? 'morning_quote' : 'evening_reflection';

  Map<String, Object?> toJson() => {
    'date': date,
    'slot': slot.name,
    'itemId': itemId,
    'text': text,
    'authorName': authorName,
    'title': title,
    'body': body,
    'payload': payload,
    'hour': hour,
    'minute': minute,
    'status': status,
    'imageUrl': imageUrl,
  };

  factory PlannedNotification.fromJson(Map<String, dynamic> map) {
    return PlannedNotification(
      date: map['date'] as String? ?? '',
      slot: (map['slot'] as String?) == 'evening'
          ? NotificationSlot.evening
          : NotificationSlot.morning,
      itemId: map['itemId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      payload: map['payload'] as String? ?? '',
      hour: (map['hour'] as num?)?.toInt() ?? 9,
      minute: (map['minute'] as num?)?.toInt() ?? 30,
      status: map['status'] as String? ?? 'scheduled',
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

class PlannerInput {
  const PlannerInput({
    required this.now,
    required this.prefs,
    required this.items,
    required this.followed,
    required this.seenIds,
    required this.notifiedAt,
    required this.streak,
    required this.viewedToday,
    required this.language,
    required this.usualMood,
    this.portraitOf,
    this.permissionGranted = true,
    this.notificationsEnabled = true,
    this.maxPerDay = maxNotificationsPerDayHardCap,
  });

  final DateTime now;
  final NotificationPrefs prefs;
  final List<Item> items;
  final Set<Field> followed;
  final Set<String> seenIds;
  final Map<String, String> notifiedAt;
  final int streak;
  final bool viewedToday;
  final String language;
  final Mood? usualMood;
  final String? Function(Item item)? portraitOf;
  final bool permissionGranted;
  final bool notificationsEnabled;
  final int maxPerDay;
}

class NotificationPlanner {
  const NotificationPlanner();

  List<PlannedNotification> plan(PlannerInput input) {
    final maxPerDay = clampNotificationsPerDay(input.maxPerDay);
    if (!canScheduleNotifications(
      granted: input.permissionGranted,
      killSwitchOn: input.notificationsEnabled,
      anySlotEnabled: input.prefs.anyEnabled,
    )) {
      return const [];
    }
    if (maxPerDay == 0) return const [];

    final today = DateTime(input.now.year, input.now.month, input.now.day);
    final blockedItems = Map<String, DateTime>.from(
      _datesFrom(input.notifiedAt),
    );
    final authorsByDate = <String, Set<String>>{};
    final out = <PlannedNotification>[];

    for (var offset = 0; offset < notificationHorizonDays; offset++) {
      final date = today.add(Duration(days: offset));
      final key = dayKey(date);
      if (input.prefs.isPausedOn(key)) continue;
      final slots = _slotsForDay(
        offset: offset,
        prefs: input.prefs,
        maxPerDay: maxPerDay,
      );
      var onThisDate = 0;
      for (final slot in slots) {
        if (onThisDate >= maxPerDay) break;
        final clock = slot == NotificationSlot.morning
            ? input.prefs.morningClock
            : input.prefs.eveningClock;
        final scheduled = DateTime(
          date.year,
          date.month,
          date.day,
          clock.hour,
          clock.minute,
        );
        if (!scheduled.isAfter(input.now)) continue;
        final item = _pick(
          input: input,
          date: date,
          dateKey: key,
          slot: slot,
          offset: offset,
          blockedItems: blockedItems,
          authorsByDate: authorsByDate,
        );
        if (item == null) continue;
        final title = _titleFor(
          input: input,
          dateKey: key,
          slot: slot,
          isToday: offset == 0,
        );
        out.add(
          PlannedNotification(
            date: key,
            slot: slot,
            itemId: item.id,
            text: item.text,
            authorName: item.author,
            title: title,
            body: notificationBody(item.text, item.author),
            payload: 'motiscroll://item/${item.id}?slot=${slot.name}&date=$key',
            hour: clock.hour,
            minute: clock.minute,
            imageUrl: input.portraitOf?.call(item) ?? item.imageUrl,
          ),
        );
        blockedItems[item.id] = date;
        authorsByDate.putIfAbsent(key, () => <String>{}).add(item.author);
        onThisDate += 1;
      }
    }

    assert(
      out.length <= maxPendingPlanNotifications,
      'The MotiScroll plan must stay under $maxPendingPlanNotifications pending notifications.',
    );
    return out;
  }

  List<NotificationSlot> _slotsForDay({
    required int offset,
    required NotificationPrefs prefs,
    required int maxPerDay,
  }) {
    final slots = <NotificationSlot>[];
    if (offset < notificationTaperAfterDays) {
      if (prefs.morningEnabled) slots.add(NotificationSlot.morning);
      if (prefs.eveningEnabled) slots.add(NotificationSlot.evening);
    } else if (prefs.morningEnabled) {
      slots.add(NotificationSlot.morning);
    } else if (prefs.eveningEnabled) {
      slots.add(NotificationSlot.evening);
    }
    if (slots.length > maxPerDay) return slots.sublist(0, maxPerDay);
    return slots;
  }

  String _titleFor({
    required PlannerInput input,
    required String dateKey,
    required NotificationSlot slot,
    required bool isToday,
  }) {
    if (slot == NotificationSlot.evening &&
        isToday &&
        input.streak >= 3 &&
        !input.viewedToday) {
      final variant = hashString('$dateKey:streak:${input.language}') % 3;
      return streakTitle(input.language, input.streak, variant);
    }
    final variant = hashString('$dateKey:${slot.name}:${input.language}');
    if (slot == NotificationSlot.morning) {
      return morningTitle(input.language, variant);
    }
    return eveningTitle(input.language, variant);
  }

  Item? _pick({
    required PlannerInput input,
    required DateTime date,
    required String dateKey,
    required NotificationSlot slot,
    required int offset,
    required Map<String, DateTime> blockedItems,
    required Map<String, Set<String>> authorsByDate,
  }) {
    final pool = [
      for (final item in input.items)
        if (_inSource(item, input) &&
            item.type != 'speech' &&
            notificationWordCount(item.text) <= notificationWordLimit &&
            item.text.trim().isNotEmpty &&
            item.author.trim().isNotEmpty)
          item,
    ];
    final ranked = [...pool]
      ..sort((a, b) {
        final score = _score(
          a,
          input,
          slot,
          offset,
        ).compareTo(_score(b, input, slot, offset));
        if (score != 0) return score;
        return hashString('$dateKey:${slot.name}:${a.id}')
            .compareTo(hashString('$dateKey:${slot.name}:${b.id}'));
      });
    for (final item in ranked) {
      if (_itemBlocked(item.id, date, blockedItems)) continue;
      if (_authorBlocked(item.author, date, authorsByDate)) continue;
      return item;
    }
    return null;
  }

  bool _inSource(Item item, PlannerInput input) {
    switch (input.prefs.quoteSource) {
      case QuoteSource.all:
        return true;
      case QuoteSource.mood:
        final mood = input.usualMood;
        if (mood == null) return true;
        return item.moods.contains(mood);
      case QuoteSource.followedFields:
        if (input.followed.isEmpty) return true;
        return input.followed.contains(item.field);
    }
  }

  int _score(Item item, PlannerInput input, NotificationSlot slot, int offset) {
    var score = 0;
    if (!input.seenIds.contains(item.id) &&
        !input.notifiedAt.containsKey(item.id)) {
      score -= 40;
    }
    if (slot == NotificationSlot.morning) {
      final rotate = _rotateField(input.followed, offset);
      if (rotate != null && item.field == rotate) score -= 12;
      if (item.field == Field.sports ||
          item.field == Field.leadership ||
          item.field == Field.business) {
        score -= 6;
      }
      if (item.moods.contains(Mood.preWorkout) ||
          item.moods.contains(Mood.needFocus)) {
        score -= 4;
      }
    } else {
      if (item.field == Field.resilience) score -= 12;
      if (item.moods.contains(Mood.feelingStuck) ||
          item.moods.contains(Mood.badDay) ||
          item.moods.contains(Mood.startingOver)) {
        score -= 6;
      }
    }
    if (input.language != 'en') {
      // Regional-voice authors are not tagged on Item; no extra score.
    }
    return score;
  }

  Field? _rotateField(Set<Field> followed, int offset) {
    if (followed.isEmpty) return null;
    final list = followed.toList()..sort((a, b) => a.name.compareTo(b.name));
    return list[offset % list.length];
  }

  bool _itemBlocked(
    String id,
    DateTime date,
    Map<String, DateTime> blockedItems,
  ) {
    final previous = blockedItems[id];
    if (previous == null) return false;
    final prev = DateTime(previous.year, previous.month, previous.day);
    return date.difference(prev).inDays < notifiedRepeatDays;
  }

  bool _authorBlocked(
    String author,
    DateTime date,
    Map<String, Set<String>> authorsByDate,
  ) {
    for (var back = 1; back < notificationAuthorWindowDays; back++) {
      final key = dayKey(date.subtract(Duration(days: back)));
      if (authorsByDate[key]?.contains(author) == true) return true;
    }
    return false;
  }

  Map<String, DateTime> _datesFrom(Map<String, String> notifiedAt) {
    final out = <String, DateTime>{};
    for (final entry in notifiedAt.entries) {
      final parsed = DateTime.tryParse(entry.value);
      if (parsed == null) continue;
      out[entry.key] = DateTime(parsed.year, parsed.month, parsed.day);
    }
    return out;
  }
}

Map<String, String> mergeFiredNotified({
  required Map<String, String> notifiedAt,
  required List<PlannedNotification> previous,
  required DateTime now,
}) {
  final next = Map<String, String>.from(notifiedAt);
  for (final row in previous) {
    final at = DateTime.tryParse(row.date);
    if (at == null) continue;
    final fired = DateTime(at.year, at.month, at.day, row.hour, row.minute);
    if (!fired.isAfter(now)) {
      next[row.itemId] = row.date;
    }
  }
  final cutoff = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: notifiedRepeatDays));
  next.removeWhere((id, date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return true;
    return parsed.isBefore(cutoff);
  });
  return next;
}
