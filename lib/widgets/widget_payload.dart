import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/languages.dart';
import '../l10n/widget_gallery.dart';
import 'generated_cover.dart';

/// A quote is shown whole on a widget, or a shorter published line is chosen.
const widgetInlineWordLimit = 8;
const widgetSmallWordLimit = 20;
const widgetMediumWordLimit = 35;
const widgetLargeWordLimit = 60;

const widgetPayloadVersion = 1;
const widgetHorizonDays = 14;
const widgetPoolSize = 15;
const widgetSavedLimit = 20;
const widgetPayloadBudget = 200 * 1024;
const widgetAppGroup = 'group.com.example.motiScroll';

/// File name the app writes and the widget reads. No path characters.
String widgetPortraitName(String id) {
  final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return '${safe.isEmpty ? 'line' : safe}.jpg';
}

const widgetPayloadKey = 'widget_payload';
const widgetSourceKey = 'widget_source_v1';
const widgetRefreshTask = 'moti-widget-refresh';

/// Shared with the app's preference blob so a background refresh can rebuild.
const widgetUserStateKey = 'moti-scroll-state';

/// One published line, reduced to what a widget paints and a tap can open.
class WidgetQuote {
  const WidgetQuote({
    required this.itemId,
    required this.text,
    required this.wordCount,
    required this.authorName,
    required this.authorRole,
    required this.sourceTitle,
    required this.sourceYear,
    required this.isTranslated,
    required this.field,
    required this.colors,
    this.takeaway,
  });

  final String itemId;
  final String text;
  final int wordCount;
  final String authorName;
  final String authorRole;
  final String sourceTitle;
  final int? sourceYear;
  final bool isTranslated;
  final String field;
  final List<String> colors;

  /// Present only for a human-reviewed takeaway. Widgets hide the line when
  /// this is null. Nothing is invented to fill it.
  final String? takeaway;

  Map<String, Object?> toJson() => {
    'itemId': itemId,
    'text': text,
    'wordCount': wordCount,
    'authorName': authorName,
    'authorRole': authorRole,
    'sourceTitle': sourceTitle,
    'sourceYear': sourceYear,
    'isTranslated': isTranslated,
    'field': field,
    'colors': colors,
    'takeaway': takeaway,
  };

  static WidgetQuote? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    final id = raw['itemId'];
    final author = raw['authorName'];
    if (text is! String || id is! String || author is! String) return null;
    if (text.isEmpty || author.isEmpty) return null;
    final colors = raw['colors'];
    return WidgetQuote(
      itemId: id,
      text: text,
      wordCount: (raw['wordCount'] as num?)?.toInt() ?? widgetWordCount(text),
      authorName: author,
      authorRole: raw['authorRole'] as String? ?? '',
      sourceTitle: raw['sourceTitle'] as String? ?? '',
      sourceYear: (raw['sourceYear'] as num?)?.toInt(),
      isTranslated: raw['isTranslated'] == true,
      field: raw['field'] as String? ?? 'other',
      colors: colors is List
          ? [
              for (final color in colors)
                if (color is String) color,
            ]
          : const ['#17191E', '#3A4150'],
      takeaway: raw['takeaway'] as String?,
    );
  }
}

class WidgetSource {
  const WidgetSource({
    required this.id,
    required this.text,
    required this.author,
    required this.authorRole,
    required this.field,
    required this.moods,
    required this.sourceTitle,
    this.sourceYear,
    this.imageUrl,
  });

  final String id;
  final String text;
  final String author;
  final String authorRole;
  final String field;
  final List<String> moods;
  final String sourceTitle;
  final int? sourceYear;
  final String? imageUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'author': author,
    'authorRole': authorRole,
    'field': field,
    'moods': moods,
    'sourceTitle': sourceTitle,
    'sourceYear': sourceYear,
    'imageUrl': imageUrl,
  };

  static WidgetSource? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final text = raw['text'];
    final author = raw['author'];
    if (id is! String || text is! String || author is! String) return null;
    final moods = raw['moods'];
    return WidgetSource(
      id: id,
      text: text,
      author: author,
      authorRole: raw['authorRole'] as String? ?? '',
      field: raw['field'] as String? ?? 'other',
      moods: moods is List
          ? [
              for (final mood in moods)
                if (mood is String) mood,
            ]
          : const [],
      sourceTitle: raw['sourceTitle'] as String? ?? '',
      sourceYear: (raw['sourceYear'] as num?)?.toInt(),
      imageUrl: raw['imageUrl'] as String?,
    );
  }
}

WidgetSource widgetSourceFromItem(Item item, {String? imageUrl}) {
  final own = item.imageUrl;
  final portrait = (own != null && own.isNotEmpty) ? own : imageUrl;
  return WidgetSource(
    id: item.id,
    text: item.text,
    author: item.author,
    authorRole: item.authorRole,
    field: item.field.name,
    moods: [for (final mood in item.moods) mood.name],
    sourceTitle: item.source.title,
    sourceYear: item.source.year,
    imageUrl: portrait,
  );
}

int widgetWordCount(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
}

class WidgetDay {
  const WidgetDay({
    required this.date,
    required this.inline,
    required this.small,
    required this.medium,
    required this.large,
  });

  final String date;
  final WidgetQuote? inline;
  final WidgetQuote? small;
  final WidgetQuote? medium;
  final WidgetQuote? large;

  Map<String, Object?> toJson() => {
    'date': date,
    'inline': inline?.toJson(),
    'small': small?.toJson(),
    'medium': medium?.toJson(),
    'large': large?.toJson(),
  };
}

class WidgetPayload {
  const WidgetPayload({
    required this.generatedAt,
    required this.contentLanguage,
    required this.direction,
    required this.streakCount,
    required this.lastActiveDate,
    required this.localizedStrings,
    required this.daily,
    required this.moodPools,
    required this.fieldPools,
    required this.saved,
    required this.followedFields,
    required this.widgetsEnabled,
    required this.showSavedOnLockScreen,
    required this.cleared,
  });

  final String? generatedAt;
  final String contentLanguage;
  final String direction;
  final int streakCount;
  final String? lastActiveDate;
  final Map<String, String> localizedStrings;
  final List<WidgetDay> daily;
  final Map<String, List<WidgetQuote>> moodPools;
  final Map<String, List<WidgetQuote>> fieldPools;
  final List<WidgetQuote> saved;
  final List<String> followedFields;
  final bool widgetsEnabled;
  final bool showSavedOnLockScreen;
  final bool cleared;

  Map<String, Object?> toJson() => {
    'version': widgetPayloadVersion,
    'generatedAt': generatedAt,
    'contentLanguage': contentLanguage,
    'direction': direction,
    'streakCount': streakCount,
    'lastActiveDate': lastActiveDate,
    'localizedStrings': localizedStrings,
    'daily': [for (final day in daily) day.toJson()],
    'moodPools': {
      for (final entry in moodPools.entries)
        entry.key: [for (final quote in entry.value) quote.toJson()],
    },
    'fieldPools': {
      for (final entry in fieldPools.entries)
        entry.key: [for (final quote in entry.value) quote.toJson()],
    },
    'saved': [for (final quote in saved) quote.toJson()],
    'followedFields': followedFields,
    'widgetsEnabled': widgetsEnabled,
    'showSavedOnLockScreen': showSavedOnLockScreen,
    'cleared': cleared,
  };

  String encode() => jsonEncode(toJson());
}

class WidgetLink {
  const WidgetLink.home() : itemId = null;

  const WidgetLink.item(this.itemId);

  final String? itemId;

  static WidgetLink? parse(Uri? uri) {
    if (uri == null || uri.scheme != 'motiscroll') return null;
    if (uri.host == 'home') return const WidgetLink.home();
    if (uri.host != 'item') return null;
    if (uri.pathSegments.isEmpty || uri.pathSegments.first.isEmpty) {
      return const WidgetLink.home();
    }
    return WidgetLink.item(uri.pathSegments.first);
  }
}

bool widgetPayloadIsStale(String? generatedAt, DateTime now) {
  if (generatedAt == null || generatedAt.isEmpty) return true;
  final at = DateTime.tryParse(generatedAt);
  if (at == null) return true;
  return now.difference(at) > const Duration(days: widgetHorizonDays);
}

/// Lines the app already decided to show. There is no `publishedLocalized`
/// collection and no `restrictedRegions` field on an item, so the caller
/// passes the same list the feed uses. Translated quotes are not invented:
/// `isTranslated` stays false until a human-reviewed translation exists.
WidgetPayload buildWidgetPayload({
  required List<WidgetSource> items,
  required DateTime now,
  required String contentLanguage,
  required String uiLanguage,
  required int streakCount,
  required String? lastActiveDate,
  required List<String> savedIds,
  required List<String> followedFields,
  required bool showSavedOnLockScreen,
}) {
  final pool = _quotesWithin(items, widgetLargeWordLimit);
  final daily = <WidgetDay>[];
  final start = DateTime(now.year, now.month, now.day);
  for (var offset = 0; offset < widgetHorizonDays; offset++) {
    final date = dayKey(start.add(Duration(days: offset)));
    daily.add(
      WidgetDay(
        date: date,
        inline: quoteForSize(pool, date, widgetInlineWordLimit),
        small: quoteForSize(pool, date, widgetSmallWordLimit),
        medium: quoteForSize(pool, date, widgetMediumWordLimit),
        large: quoteForSize(pool, date, widgetLargeWordLimit),
      ),
    );
  }
  final byId = {for (final item in items) item.id: item};
  final saved = <WidgetQuote>[];
  for (final id in savedIds) {
    if (saved.length >= widgetSavedLimit) break;
    final item = byId[id];
    if (item == null) continue;
    final quote = _quoteFrom(item);
    if (quote == null || quote.wordCount > widgetMediumWordLimit) continue;
    saved.add(quote);
  }
  return WidgetPayload(
    generatedAt: now.toUtc().toIso8601String(),
    contentLanguage: contentLanguage,
    direction: _direction(contentLanguage),
    streakCount: streakCount,
    lastActiveDate: lastActiveDate,
    localizedStrings: widgetRuntimeStrings(uiLanguage),
    daily: daily,
    moodPools: _namedPools(
      pool,
      (quote) => _moodsOf(items, quote.itemId),
      'mood',
    ),
    fieldPools: _namedPools(pool, (quote) => [quote.field], 'field'),
    saved: saved,
    followedFields: followedFields,
    widgetsEnabled: true,
    showSavedOnLockScreen: showSavedOnLockScreen,
    cleared: false,
  );
}

WidgetPayload widgetPayloadDisabled({
  required DateTime now,
  required String contentLanguage,
  required String uiLanguage,
}) {
  return WidgetPayload(
    generatedAt: now.toUtc().toIso8601String(),
    contentLanguage: contentLanguage,
    direction: _direction(contentLanguage),
    streakCount: 0,
    lastActiveDate: null,
    localizedStrings: widgetRuntimeStrings(uiLanguage),
    daily: const [],
    moodPools: const {},
    fieldPools: const {},
    saved: const [],
    followedFields: const [],
    widgetsEnabled: false,
    showSavedOnLockScreen: false,
    cleared: false,
  );
}

WidgetPayload widgetPayloadCleared({
  required String contentLanguage,
  required String uiLanguage,
}) {
  return WidgetPayload(
    generatedAt: null,
    contentLanguage: contentLanguage,
    direction: _direction(contentLanguage),
    streakCount: 0,
    lastActiveDate: null,
    localizedStrings: widgetRuntimeStrings(uiLanguage),
    daily: const [],
    moodPools: const {},
    fieldPools: const {},
    saved: const [],
    followedFields: const [],
    widgetsEnabled: true,
    showSavedOnLockScreen: false,
    cleared: true,
  );
}

/// Up to forty lines per field that already fit the largest widget.
List<WidgetSource> widgetSourceSnapshot(List<WidgetSource> items) {
  final byField = <String, List<WidgetSource>>{};
  for (final item in items) {
    if (item.text.trim().isEmpty || item.author.trim().isEmpty) continue;
    if (widgetWordCount(item.text) > widgetLargeWordLimit) continue;
    byField.putIfAbsent(item.field, () => []).add(item);
  }
  final out = <WidgetSource>[];
  for (final list in byField.values) {
    final sorted = [...list]..sort((a, b) => a.id.compareTo(b.id));
    out.addAll(sorted.take(40));
  }
  return out;
}

/// Today's line is the hash pick. A smaller widget uses that line when it
/// fits and otherwise the next published line in the same pool that does.
WidgetQuote? quoteForSize(List<WidgetQuote> pool, String date, int limit) {
  if (pool.isEmpty) return null;
  final todayIndex = hashString('$date:daily') % pool.length;
  final today = pool[todayIndex];
  if (today.wordCount <= limit) return today;
  for (var step = 1; step <= pool.length; step++) {
    final candidate = pool[(todayIndex + step) % pool.length];
    if (candidate.wordCount <= limit) return candidate;
  }
  return null;
}

String _direction(String contentLanguage) {
  return languageByCode(contentLanguage)?.rtl == true ? 'rtl' : 'ltr';
}

List<WidgetQuote> _quotesWithin(List<WidgetSource> items, int limit) {
  final quotes = <WidgetQuote>[];
  for (final item in items) {
    final quote = _quoteFrom(item);
    if (quote != null && quote.wordCount <= limit) quotes.add(quote);
  }
  quotes.sort((a, b) => a.itemId.compareTo(b.itemId));
  return quotes;
}

WidgetQuote? _quoteFrom(WidgetSource item) {
  final text = item.text.trim();
  final author = item.author.trim();
  final words = widgetWordCount(text);
  if (text.isEmpty || author.isEmpty || words == 0) return null;
  return WidgetQuote(
    itemId: item.id,
    text: item.text,
    wordCount: words,
    authorName: item.author,
    authorRole: item.authorRole,
    sourceTitle: item.sourceTitle,
    sourceYear: item.sourceYear,
    isTranslated: false,
    field: item.field,
    colors: _fieldColors(item.field),
  );
}

List<String> _fieldColors(String fieldName) {
  final field = _field(fieldName);
  final palette = coverPalettes[field] ?? coverPalettes[Field.other]!;
  return [_hex(palette[2]), _hex(palette[1])];
}

String _hex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Field _field(String name) {
  for (final field in Field.values) {
    if (field.name == name) return field;
  }
  return Field.other;
}

List<String> _moodsOf(List<WidgetSource> items, String id) {
  for (final item in items) {
    if (item.id == id) return item.moods;
  }
  return const [];
}

Map<String, List<WidgetQuote>> _namedPools(
  List<WidgetQuote> pool,
  List<String> Function(WidgetQuote quote) keysOf,
  String salt,
) {
  final grouped = <String, List<WidgetQuote>>{};
  for (final quote in pool) {
    if (quote.wordCount > widgetMediumWordLimit) continue;
    for (final key in keysOf(quote)) {
      grouped.putIfAbsent(key, () => []).add(quote);
    }
  }
  return {
    for (final entry in grouped.entries)
      entry.key: _slice(entry.value, '$salt:${entry.key}', widgetPoolSize),
  };
}

List<WidgetQuote> _slice(List<WidgetQuote> quotes, String salt, int size) {
  if (quotes.isEmpty) return const [];
  final sorted = [...quotes]..sort((a, b) => a.itemId.compareTo(b.itemId));
  final start = hashString(salt) % sorted.length;
  final out = <WidgetQuote>[];
  for (var i = 0; i < sorted.length && out.length < size; i++) {
    out.add(sorted[(start + i) % sorted.length]);
  }
  return out;
}

WidgetPayload? payloadFromStored({
  required String? userJson,
  required String? sourceJson,
  required DateTime now,
}) {
  Map<String, dynamic> user = const {};
  if (userJson != null && userJson.isNotEmpty) {
    try {
      final decoded = jsonDecode(userJson);
      if (decoded is Map<String, dynamic>) user = decoded;
    } on FormatException {
      user = const {};
    }
  }
  final language =
      languageByCode(user['contentLanguage'] as String?)?.code ?? 'en';
  final uiLanguage =
      languageByCode(user['uiLanguage'] as String?)?.code ?? language;
  if (user['widgetsEnabled'] == false) {
    return widgetPayloadDisabled(
      now: now,
      contentLanguage: language,
      uiLanguage: uiLanguage,
    );
  }
  if (sourceJson == null || sourceJson.isEmpty) return null;
  List<WidgetSource> sources;
  try {
    final decoded = jsonDecode(sourceJson);
    if (decoded is! List) return null;
    sources = [for (final row in decoded) ?WidgetSource.fromJson(row)];
  } on FormatException {
    return null;
  }
  if (sources.isEmpty) return null;
  final saved = user['saved'];
  final followed = user['followed'];
  return buildWidgetPayload(
    items: sources,
    now: now,
    contentLanguage: language,
    uiLanguage: uiLanguage,
    streakCount: (user['streak'] as num?)?.toInt() ?? 0,
    lastActiveDate: user['lastStreakDate'] as String?,
    savedIds: saved is List
        ? [
            for (final id in saved)
              if (id is String) id,
          ]
        : const [],
    followedFields: followed is List
        ? [
            for (final field in followed)
              if (field is String) field,
          ]
        : const [],
    showSavedOnLockScreen: user['showSavedOnLockScreen'] == true,
  );
}
