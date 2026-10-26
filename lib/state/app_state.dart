import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/discover_deck.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../theme/tokens.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'moti-scroll-state';

  bool dark = true;
  bool onboardingComplete = false;
  Mood? usualMood;
  int streak = 0;
  String? lastStreakDate;
  bool hintDismissed = false;
  bool reminderOn = false;
  int bestStreak = 0;
  String? feedTarget;
  final liked = <String>{};
  final saved = <String>{};
  final read = <String>{};
  final visitDays = <String>{};
  final notes = <String, String>{};
  final followed = <Field>{};
  List<Item> items = kItems;
  List<Item> discoverItems = const [];
  Item? daily;
  bool remote = false;
  bool catalogLoading = false;
  bool feedHasMore = false;
  String? catalogError;
  String? accountLabel;
  ItemRepository repository = LocalItemRepository(kItems);
  UserDirectory? directory;
  Future<int?> Function(String itemId)? syncView;
  final discoverDeck = DiscoverDeck();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) _read(decoded);
      } on FormatException {
        // Keep defaults when the stored blob is unreadable.
      }
    }
  }

  void _read(Map<String, dynamic> map) {
    dark = map['dark'] as bool? ?? true;
    onboardingComplete = map['onboardingComplete'] as bool? ?? false;
    usualMood = _mood(map['usualMood'] as String?);
    streak = (map['streak'] as num?)?.toInt() ?? 0;
    lastStreakDate = map['lastStreakDate'] as String?;
    hintDismissed = map['hintDismissed'] as bool? ?? false;
    reminderOn = map['reminderOn'] as bool? ?? false;
    bestStreak = (map['bestStreak'] as num?)?.toInt() ?? 0;
    liked
      ..clear()
      ..addAll(_strings(map['liked']));
    saved
      ..clear()
      ..addAll(_strings(map['saved']));
    read
      ..clear()
      ..addAll(_strings(map['read']));
    visitDays
      ..clear()
      ..addAll(_strings(map['visitDays']));
    notes
      ..clear()
      ..addAll(_stringMap(map['notes']));
    followed
      ..clear()
      ..addAll(_strings(map['followed']).map(_field).whereType<Field>());
  }

  Map<String, Object?> _toJson() => {
    'dark': dark,
    'onboardingComplete': onboardingComplete,
    'usualMood': usualMood?.name,
    'streak': streak,
    'lastStreakDate': lastStreakDate,
    'hintDismissed': hintDismissed,
    'reminderOn': reminderOn,
    'bestStreak': bestStreak,
    'liked': liked.toList(),
    'saved': saved.toList(),
    'read': read.toList(),
    'visitDays': visitDays.toList(),
    'notes': notes,
    'followed': followed.map((field) => field.name).toList(),
  };

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_toJson()));
    } on Exception {
      return;
    }
  }

  void _touch() {
    notifyListeners();
    _persist();
  }

  void toggleLike(String id) {
    final on = liked.add(id);
    if (!on) liked.remove(id);
    _touch();
    directory?.setFlag(collection: 'liked', id: id, on: on);
  }

  void toggleSave(String id) {
    final on = saved.add(id);
    if (!on) saved.remove(id);
    _touch();
    directory?.setFlag(collection: 'saved', id: id, on: on);
  }

  void toggleRead(String id) {
    if (!read.add(id)) read.remove(id);
    _touch();
  }

  void setNote(String id, String value) {
    if (value.trim().isEmpty) {
      notes.remove(id);
    } else {
      notes[id] = value.trim();
    }
    _touch();
  }

  void openInFeed(String id) {
    feedTarget = id;
    final today = dayKey(DateTime.now());
    final alreadyToday = lastStreakDate == today;
    noteVisit();
    if (alreadyToday) _touch();
    _syncView(id);
  }

  void consumeFeedTarget() {
    feedTarget = null;
  }

  void toggleFollow(Field field) {
    final on = followed.add(field);
    if (!on) followed.remove(field);
    _touch();
    directory?.setFlag(collection: 'followedFields', id: field.name, on: on);
  }

  void setMood(Mood mood) {
    if (usualMood == mood) return;
    usualMood = mood;
    _touch();
  }

  void setDark(bool value) {
    if (dark == value) return;
    dark = value;
    _touch();
  }

  void dismissHint() {
    if (hintDismissed) return;
    hintDismissed = true;
    _touch();
  }

  void setReminder(bool value) {
    if (reminderOn == value) return;
    reminderOn = value;
    _touch();
  }

  void noteVisit() {
    final now = DateTime.now();
    final today = dayKey(now);
    if (lastStreakDate == today) {
      if (visitDays.add(today)) _touch();
      return;
    }
    final start = DateTime(now.year, now.month, now.day);
    final yesterday = dayKey(start.subtract(const Duration(days: 1)));
    streak = lastStreakDate == yesterday ? streak + 1 : 1;
    if (streak > bestStreak) bestStreak = streak;
    lastStreakDate = today;
    visitDays.add(today);
    _touch();
  }

  void completeOnboarding({required Set<Field> fields, required Mood? mood}) {
    followed
      ..clear()
      ..addAll(fields);
    usualMood = mood;
    onboardingComplete = true;
    _touch();
    _publishProfile();
  }

  Future<void> refreshCatalog() async {
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    try {
      final page = await repository.page();
      items = page.items;
      discoverItems = (await repository.discover(
        followed: followed,
        deck: discoverDeck,
      )).items;
      daily = await repository.quoteOfDay(DateTime.now());
      feedHasMore = remote && page.items.length >= 20;
      catalogLoading = false;
      catalogError = null;
      notifyListeners();
    } on Exception {
      catalogLoading = false;
      catalogError = 'The library could not be opened.';
      if (!remote) items = kItems;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!remote || catalogLoading || !feedHasMore) return;
    catalogLoading = true;
    notifyListeners();
    try {
      final page = await repository.page(more: true);
      final known = items.map((item) => item.id).toSet();
      items = [
        ...items,
        for (final item in page.items)
          if (known.add(item.id)) item,
      ];
      feedHasMore = page.items.length >= 20;
    } on Exception {
      catalogError = 'The next page could not be loaded.';
    }
    catalogLoading = false;
    notifyListeners();
  }

  Future<void> reportItem(String itemId, String reason, String note) async {
    final directory = this.directory;
    if (directory == null) return;
    await directory.report(itemId: itemId, reason: reason, note: note);
  }

  void noteLine(String id) {
    noteVisit();
    _syncView(id);
  }

  void _syncView(String id) {
    final sync = syncView;
    if (sync == null) return;
    sync(id).then((value) {
      if (value == null || value == streak) return;
      streak = value;
      if (streak > bestStreak) bestStreak = streak;
      _touch();
    });
  }

  Future<void> _publishProfile() async {
    final directory = this.directory;
    if (directory == null) return;
    var zone = 'UTC';
    try {
      zone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Exception {
      zone = 'UTC';
    }
    try {
      await directory.ensureProfile(
        fields: followed,
        mood: usualMood,
        timezone: zone,
        reminderTime: '08:00',
        reminderLocal: reminderOn,
      );
    } on Exception {
      return;
    }
  }

  void replayOnboarding() {
    onboardingComplete = false;
    _touch();
  }

  void resetProgress() {
    liked.clear();
    saved.clear();
    followed.clear();
    streak = 0;
    bestStreak = 0;
    lastStreakDate = null;
    hintDismissed = false;
    read.clear();
    visitDays.clear();
    notes.clear();
    _touch();
  }

  Palette get palette => dark ? darkPalette : lightPalette;

  void notifyAccount() => _touch();
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing');
    return scope!.notifier!;
  }
}

Mood? _mood(String? name) {
  for (final mood in Mood.values) {
    if (mood.name == name) return mood;
  }
  return null;
}

Field? _field(String name) {
  for (final field in Field.values) {
    if (field.name == name) return field;
  }
  return null;
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry('$key', '$item'));
}
