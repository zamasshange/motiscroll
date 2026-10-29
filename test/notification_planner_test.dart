import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/notifications/notification_planner.dart';
import 'package:moti_scroll/notifications/notification_prefs.dart';
import 'package:moti_scroll/notifications/notification_schedule.dart';
import 'package:moti_scroll/notifications/notification_text.dart';
import 'package:moti_scroll/widgets/widget_payload.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  final planner = const NotificationPlanner();
  final now = DateTime(2026, 10, 29, 7, 0);

  PlannerInput input({
    List<Item>? items,
    NotificationPrefs prefs = const NotificationPrefs(),
    Set<Field> followed = const {},
    Set<String> seen = const {},
    Map<String, String> notified = const {},
    int streak = 0,
    bool viewedToday = false,
    String language = 'en',
    Mood? mood,
    bool granted = true,
    bool enabled = true,
    int maxPerDay = 2,
    DateTime? at,
  }) {
    return PlannerInput(
      now: at ?? now,
      prefs: prefs,
      items: items ?? _pool(),
      followed: followed,
      seenIds: seen,
      notifiedAt: notified,
      streak: streak,
      viewedToday: viewedToday,
      language: language,
      usualMood: mood,
      permissionGranted: granted,
      notificationsEnabled: enabled,
      maxPerDay: maxPerDay,
    );
  }

  test('14-day horizon tapers after seven days', () {
    final plan = planner.plan(input());
    expect(plan.length, lessThanOrEqualTo(maxPendingPlanNotifications));
    expect(plan.length, 21);
    final byDate = <String, int>{};
    for (final row in plan) {
      byDate[row.date] = (byDate[row.date] ?? 0) + 1;
    }
    expect(byDate.length, 14);
    final dates = byDate.keys.toList()..sort();
    for (var i = 0; i < 7; i++) {
      expect(byDate[dates[i]], 2, reason: dates[i]);
    }
    for (var i = 7; i < 14; i++) {
      expect(byDate[dates[i]], 1, reason: dates[i]);
      expect(
        plan.where((row) => row.date == dates[i]).single.slot,
        NotificationSlot.morning,
      );
    }
  });

  test('hard cap is two per day and a constant of 2', () {
    expect(maxNotificationsPerDayHardCap, 2);
    expect(clampNotificationsPerDay(9), 2);
    final plan = planner.plan(input(maxPerDay: 9));
    final byDate = <String, int>{};
    for (final row in plan) {
      byDate[row.date] = (byDate[row.date] ?? 0) + 1;
    }
    expect(byDate.values.every((count) => count <= 2), isTrue);
  });

  test('taper uses evening when morning is off', () {
    final plan = planner.plan(
      input(
        prefs: const NotificationPrefs(morningEnabled: false),
      ),
    );
    expect(plan.every((row) => row.slot == NotificationSlot.evening), isTrue);
    expect(plan.length, 14);
  });

  test('no item repeats within 60 days', () {
    final items = _pool();
    final first = planner.plan(input(items: items));
    expect(first.map((row) => row.itemId).toSet().length, first.length);
    final notified = {
      for (final row in first) row.itemId: row.date,
    };
    final later = planner.plan(
      input(
        items: items,
        notified: notified,
        at: DateTime(2026, 11, 12, 7),
      ),
    );
    final reused = later.where((row) => notified.containsKey(row.itemId));
    expect(reused, isEmpty);
  });

  test('no author appears twice in a 3-day window', () {
    final plan = planner.plan(input());
    for (var i = 0; i < plan.length; i++) {
      for (var j = i + 1; j < plan.length; j++) {
        if (plan[i].authorName != plan[j].authorName) continue;
        final a = DateTime.parse(plan[i].date);
        final b = DateTime.parse(plan[j].date);
        expect(b.difference(a).inDays.abs() >= 3, isTrue);
      }
    }
  });

  test('word-count limit skips long quotes and never truncates', () {
    final long = _item('long', 'Long Author', words: 40);
    final short = _item('short', 'Short Author', words: 8);
    final plan = planner.plan(input(items: [long, short]));
    expect(plan.every((row) => row.itemId == 'short'), isTrue);
    expect(plan.every((row) => row.body.startsWith(short.text)), isTrue);
    expect(plan.every((row) => row.body.contains(short.text)), isTrue);
  });

  test('a small pool schedules fewer days rather than repeating', () {
    final items = [
      _item('a', 'Author A'),
      _item('b', 'Author B'),
      _item('c', 'Author C'),
    ];
    final plan = planner.plan(input(items: items));
    expect(plan.length, lessThan(21));
    expect(plan.map((row) => row.itemId).toSet().length, plan.length);
  });

  test('pause skips dates before pausedUntil', () {
    final plan = planner.plan(
      input(
        prefs: const NotificationPrefs(pausedUntil: '2026-11-05'),
      ),
    );
    expect(plan.every((row) => row.date.compareTo('2026-11-05') >= 0), isTrue);
    expect(plan, isNotEmpty);
  });

  test('streak title is only for today evening', () {
    final plan = planner.plan(
      input(streak: 5, viewedToday: false),
    );
    final todayEvening = plan.where(
      (row) => row.date == '2026-10-29' && row.slot == NotificationSlot.evening,
    );
    expect(todayEvening, isNotEmpty);
    expect(todayEvening.single.title.contains('5'), isTrue);
    final laterEvening = plan.where(
      (row) => row.date != '2026-10-29' && row.slot == NotificationSlot.evening,
    );
    expect(
      laterEvening.every((row) => !row.title.contains('streak')),
      isTrue,
    );
  });

  test('viewing today restores a normal evening title', () {
    final plan = planner.plan(input(streak: 5, viewedToday: true));
    final todayEvening = plan.singleWhere(
      (row) => row.date == '2026-10-29' && row.slot == NotificationSlot.evening,
    );
    expect(todayEvening.title.contains('5'), isFalse);
  });

  test('titles are deterministic for a day and language', () {
    final a = planner.plan(input());
    final b = planner.plan(input());
    expect(
      [for (final row in a) row.title],
      [for (final row in b) row.title],
    );
    expect(
      [for (final row in a) row.itemId],
      [for (final row in b) row.itemId],
    );
  });

  test('language change updates titles, not quote text', () {
    final en = planner.plan(input(language: 'en'));
    final ar = planner.plan(input(language: 'ar'));
    expect(en.first.itemId, ar.first.itemId);
    expect(en.first.text, ar.first.text);
    expect(en.first.title, isNot(ar.first.title));
    expect(ar.first.body.contains(ar.first.text), isTrue);
  });

  test('restricted regions are the caller’s already-filtered catalog', () {
    final plan = planner.plan(
      input(items: [_item('only', 'Only Author')]),
    );
    expect(plan.every((row) => row.itemId == 'only'), isTrue);
  });

  test('empty cache yields an empty plan', () {
    expect(planner.plan(input(items: const [])), isEmpty);
  });

  test('kill switch, denied permission, and disabled slots schedule nothing', () {
    expect(planner.plan(input(enabled: false)), isEmpty);
    expect(planner.plan(input(granted: false)), isEmpty);
    expect(
      planner.plan(
        input(
          prefs: const NotificationPrefs(
            morningEnabled: false,
            eveningEnabled: false,
          ),
        ),
      ),
      isEmpty,
    );
  });

  test('past slots today are skipped', () {
    final plan = planner.plan(
      input(at: DateTime(2026, 10, 29, 12, 0)),
    );
    expect(
      plan.any(
        (row) =>
            row.date == '2026-10-29' && row.slot == NotificationSlot.morning,
      ),
      isFalse,
    );
    expect(
      plan.any(
        (row) =>
            row.date == '2026-10-29' && row.slot == NotificationSlot.evening,
      ),
      isTrue,
    );
  });

  test('every language has eight morning and eight evening titles', () {
    expect(notificationTitlesCoverLanguages(), isTrue);
    expect(morningTitleVariants('en'), hasLength(8));
    expect(eveningTitleVariants('en'), hasLength(8));
  });

  test('payload is the MotiScroll item deep link', () {
    final row = planner.plan(input()).first;
    expect(row.payload, startsWith('motiscroll://item/${row.itemId}'));
    final link = WidgetLink.parse(Uri.parse(row.payload));
    expect(link?.itemId, row.itemId);
  });

  test('DST spring-forward uses the tz database, not a hardcoded offset', () {
    tzdata.initializeTimeZones();
    final nyc = tz.getLocation('America/New_York');
    final saturday = zonedWallClock(
      location: nyc,
      date: DateTime(2026, 3, 7),
      hour: 9,
      minute: 30,
    );
    final sunday = zonedWallClock(
      location: nyc,
      date: DateTime(2026, 3, 8),
      hour: 9,
      minute: 30,
    );
    expect(saturday.timeZoneOffset, const Duration(hours: -5));
    expect(sunday.timeZoneOffset, const Duration(hours: -4));
    expect(sunday.difference(saturday), const Duration(hours: 23));
  });

  test('India half-hour zone keeps 09:30 local', () {
    tzdata.initializeTimeZones();
    final kolkata = tz.getLocation('Asia/Kolkata');
    final when = zonedWallClock(
      location: kolkata,
      date: DateTime(2026, 10, 29),
      hour: 9,
      minute: 30,
    );
    expect(when.hour, 9);
    expect(when.minute, 30);
    expect(when.timeZoneOffset, const Duration(hours: 5, minutes: 30));
  });

  test('timezone change is detected between opens', () {
    expect(timezoneChanged('America/New_York', 'Asia/Kolkata'), isTrue);
    expect(timezoneChanged('Asia/Kolkata', 'Asia/Kolkata'), isFalse);
  });

  test('Arabic streak lines have plural forms', () {
    expect(streakTitle('ar', 1, 0).contains('1'), isTrue);
    expect(streakTitle('ar', 2, 0), isNot(streakTitle('ar', 5, 0)));
    expect(streakTitle('ru', 1, 1), isNot(streakTitle('ru', 5, 1)));
  });

  test('RTL quote with a Latin author and mixed scripts stay intact', () {
    final arabic = Item(
      id: 'ar-1',
      type: 'quote',
      text: 'الصبر مفتاح الفرج',
      author: 'Sample Author',
      authorRole: 'Test',
      field: Field.resilience,
      moods: const [Mood.feelingStuck],
      source: const Source(title: 'Test source', year: 2000),
      verified: true,
      deeper: const Deeper(
        context: '',
        didYouKnow: '',
        takeaway: '',
        related: [],
      ),
    );
    final mixed = Item(
      id: 'mix-1',
      type: 'quote',
      text: 'Hold fast — صبر وامید',
      author: 'Sample Author B',
      authorRole: 'Test',
      field: Field.leadership,
      moods: const [Mood.needFocus],
      source: const Source(title: 'Test source', year: 2000),
      verified: true,
      deeper: const Deeper(
        context: '',
        didYouKnow: '',
        takeaway: '',
        related: [],
      ),
    );
    final plan = planner.plan(input(items: [arabic, mixed], language: 'ar'));
    expect(plan, isNotEmpty);
    expect(plan.any((row) => row.body.contains('الصبر مفتاح الفرج')), isTrue);
    expect(plan.any((row) => row.body.contains('Hold fast — صبر وامید')), isTrue);
    expect(plan.every((row) => row.body.contains('— ')), isTrue);
  });
}

List<Item> _pool() {
  return [
    for (var i = 0; i < 40; i++)
      _item(
        'item-$i',
        'Author $i',
        field: Field.values[i % Field.values.length],
        moods: [Mood.values[i % Mood.values.length]],
      ),
  ];
}

Item _item(
  String id,
  String author, {
  Field field = Field.leadership,
  List<Mood> moods = const [Mood.needFocus],
  int words = 8,
}) {
  return Item(
    id: id,
    type: 'quote',
    text: List.filled(words, 'word').join(' '),
    author: author,
    authorRole: 'Test',
    field: field,
    moods: moods,
    source: const Source(title: 'Test source', year: 2000),
    verified: true,
    deeper: const Deeper(
      context: '',
      didYouKnow: '',
      takeaway: '',
      related: [],
    ),
  );
}
