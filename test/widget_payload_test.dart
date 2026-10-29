import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/l10n/widget_gallery.dart';
import 'package:moti_scroll/widgets/widget_payload.dart';

void main() {
  test('gallery strings exist in every supported language', () {
    for (final entry in widgetGallery.entries) {
      expect(
        entry.value.keys.toSet(),
        widgetLanguageCodes.toSet(),
        reason: entry.key,
      );
      expect(entry.value['en'], isNotEmpty);
    }
  });

  test('payload keeps fourteen days and the original text', () {
    final now = DateTime(2026, 10, 28, 9);
    final payload = buildWidgetPayload(
      items: [
        _source('short', 'Four short words here today really', words: 6),
        _source(
          'mid',
          'A medium line ${List.filled(22, 'word').join(' ')}',
          words: 25,
        ),
      ],
      now: now,
      contentLanguage: 'en',
      uiLanguage: 'en',
      streakCount: 3,
      lastActiveDate: '2026-10-28',
      savedIds: const ['short'],
      followedFields: const ['leadership'],
      showSavedOnLockScreen: false,
    );
    expect(payload.daily, hasLength(14));
    expect(payload.daily.first.date, '2026-10-28');
    expect(payload.daily.last.date, '2026-11-10');
    expect(payload.streakCount, 3);
    expect(payload.direction, 'ltr');
    expect(payload.saved, hasLength(1));
    expect(payload.saved.single.text, contains('Four short words'));
    for (final day in payload.daily) {
      for (final quote in [day.inline, day.small, day.medium, day.large]) {
        if (quote == null) continue;
        expect(quote.isTranslated, isFalse);
        expect(
          quote.text == 'Four short words here today really' ||
              quote.text.startsWith('A medium line'),
          isTrue,
        );
      }
    }
    expect(utf8.encode(payload.encode()).length, lessThan(widgetPayloadBudget));
  });

  test('a size that cannot hold today uses the next fitting line', () {
    final pool = [
      WidgetQuote(
        itemId: 'long',
        text: 'word ' * 40,
        wordCount: 40,
        authorName: 'Sample',
        authorRole: '',
        sourceTitle: 'Notes',
        sourceYear: null,
        isTranslated: false,
        field: 'other',
        colors: const ['#17191E', '#3A4150'],
      ),
      WidgetQuote(
        itemId: 'brief',
        text: 'Four words fit here',
        wordCount: 4,
        authorName: 'Sample',
        authorRole: '',
        sourceTitle: 'Notes',
        sourceYear: null,
        isTranslated: false,
        field: 'other',
        colors: const ['#17191E', '#3A4150'],
      ),
    ];
    String? date;
    for (var day = 1; day <= 28; day++) {
      final candidate = '2026-10-${day.toString().padLeft(2, '0')}';
      if (hashString('$candidate:daily') % pool.length == 0) {
        date = candidate;
        break;
      }
    }
    expect(date, isNotNull);
    expect(quoteForSize(pool, date!, widgetLargeWordLimit)?.itemId, 'long');
    expect(quoteForSize(pool, date, widgetSmallWordLimit)?.itemId, 'brief');
    expect(quoteForSize(pool, date, widgetSmallWordLimit)?.text, 'Four words fit here');
  });

  test('Arabic content lays out right to left', () {
    final payload = buildWidgetPayload(
      items: [_source('ar-line', 'كلمة كلمة كلمة كلمة', words: 4)],
      now: DateTime(2026, 10, 28),
      contentLanguage: 'ar',
      uiLanguage: 'ar',
      streakCount: 0,
      lastActiveDate: null,
      savedIds: const [],
      followedFields: const [],
      showSavedOnLockScreen: false,
    );
    expect(payload.direction, 'rtl');
    expect(payload.contentLanguage, 'ar');
    expect(payload.localizedStrings['quoteOfTheDay'], 'اقتباس اليوم');
  });

  test('only the lines passed in can appear', () {
    final payload = buildWidgetPayload(
      items: [_source('kept', 'Kept words stay whole here', words: 5)],
      now: DateTime(2026, 10, 28),
      contentLanguage: 'en',
      uiLanguage: 'en',
      streakCount: 0,
      lastActiveDate: null,
      savedIds: const ['missing', 'kept'],
      followedFields: const [],
      showSavedOnLockScreen: false,
    );
    final ids = <String>{
      for (final day in payload.daily) ...[
        if (day.large != null) day.large!.itemId,
        if (day.small != null) day.small!.itemId,
      ],
      for (final quote in payload.saved) quote.itemId,
      for (final pool in payload.fieldPools.values)
        for (final quote in pool) quote.itemId,
    };
    expect(ids, {'kept'});
    expect(payload.saved.single.itemId, 'kept');
  });

  test('empty library still carries the empty-state strings', () {
    final payload = buildWidgetPayload(
      items: const [],
      now: DateTime(2026, 10, 28),
      contentLanguage: 'en',
      uiLanguage: 'en',
      streakCount: 0,
      lastActiveDate: null,
      savedIds: const [],
      followedFields: const [],
      showSavedOnLockScreen: false,
    );
    expect(payload.daily, hasLength(14));
    expect(payload.daily.first.large, isNull);
    expect(payload.saved, isEmpty);
    expect(payload.localizedStrings['saveAQuote'], 'Save a quote to see it here');
    expect(
      payload.localizedStrings['yourDailyQuote'],
      'Your daily quote appears here',
    );
  });

  test('a cleared or old payload is stale and a disabled one has no lines', () {
    final cleared = widgetPayloadCleared(
      contentLanguage: 'en',
      uiLanguage: 'en',
    );
    expect(cleared.cleared, isTrue);
    expect(
      widgetPayloadIsStale(cleared.generatedAt, DateTime(2026, 10, 28)),
      isTrue,
    );
    final old = DateTime.utc(2026, 10, 1).toIso8601String();
    expect(widgetPayloadIsStale(old, DateTime.utc(2026, 10, 20)), isTrue);
    expect(widgetPayloadIsStale(old, DateTime.utc(2026, 10, 10)), isFalse);
    final off = widgetPayloadDisabled(
      now: DateTime(2026, 10, 28),
      contentLanguage: 'en',
      uiLanguage: 'en',
    );
    expect(off.widgetsEnabled, isFalse);
    expect(off.daily, isEmpty);
  });

  test('stored cache rebuilds the payload without a network call', () {
    final source = widgetSourceSnapshot([
      _source('cached', 'Cached words remain intact', words: 4),
    ]);
    final payload = payloadFromStored(
      userJson: jsonEncode({
        'streak': 4,
        'contentLanguage': 'fr',
        'uiLanguage': 'fr',
        'saved': ['cached'],
        'followed': ['science'],
        'widgetsEnabled': true,
      }),
      sourceJson: jsonEncode([for (final item in source) item.toJson()]),
      now: DateTime(2026, 10, 28),
    );
    expect(payload, isNotNull);
    expect(payload!.streakCount, 4);
    expect(payload.contentLanguage, 'fr');
    expect(payload.direction, 'ltr');
    expect(payload.saved.single.text, 'Cached words remain intact');
    expect(payload.localizedStrings['widgets'], 'Widgets');

    final disabled = payloadFromStored(
      userJson: jsonEncode({'widgetsEnabled': false, 'contentLanguage': 'en'}),
      sourceJson: jsonEncode([for (final item in source) item.toJson()]),
      now: DateTime(2026, 10, 28),
    );
    expect(disabled!.widgetsEnabled, isFalse);
    expect(disabled.daily, isEmpty);
  });

  test('deep links open an item or home', () {
    expect(WidgetLink.parse(Uri.parse('motiscroll://item/line-1'))?.itemId, 'line-1');
    expect(WidgetLink.parse(Uri.parse('motiscroll://home'))?.itemId, isNull);
    expect(WidgetLink.parse(Uri.parse('motiscroll://item/'))?.itemId, isNull);
    expect(WidgetLink.parse(Uri.parse('https://example.com/item/line-1')), isNull);
    expect(WidgetLink.parse(null), isNull);
  });
}

WidgetSource _source(String id, String text, {required int words}) {
  expect(widgetWordCount(text), words);
  return WidgetSource(
    id: id,
    text: text,
    author: 'Sample',
    authorRole: 'Reader',
    field: 'leadership',
    moods: const ['needFocus'],
    sourceTitle: 'Notes',
    sourceYear: 2020,
  );
}
