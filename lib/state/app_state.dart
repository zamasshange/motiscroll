import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/discover_deck.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/roster_lines.dart';
import '../l10n/languages.dart';
import '../notifications/notification_planner.dart';
import '../notifications/notification_prefs.dart';
import '../notifications/notification_service.dart';
import '../notifications/notification_text.dart';
import '../share/share_caption.dart';
import '../tabs.dart';
import '../theme/tokens.dart';
import '../widgets/widget_payload.dart';
import '../widgets/widget_sync.dart';

String libraryFailure(Object _) => 'The library could not be opened.';

String _quoteSlug(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class AppState extends ChangeNotifier {
  static const _storageKey = widgetUserStateKey;

  bool dark = true;
  bool followSystemTheme = false;
  bool largeText = false;
  bool onboardingComplete = false;
  Mood? usualMood;
  int streak = 0;
  String? lastStreakDate;
  bool hintDismissed = false;
  bool reminderOn = false;
  NotificationPrefs notificationPrefs = const NotificationPrefs();
  bool notificationPermissionGranted = false;
  bool notificationsEnabled = true;
  int maxNotificationsPerDay = maxNotificationsPerDayHardCap;
  int notificationAskCount = 0;
  bool notificationAskPending = false;
  String? lastItemViewDate;
  List<PlannedNotification> notificationPlan = const [];
  int bestStreak = 0;
  String? contentLanguage;
  String? uiLanguage;
  String? secondLanguage;
  bool widgetsEnabled = true;
  bool showSavedOnLockScreen = false;
  String? feedTarget;
  Field? collectionFocus;
  int? pendingTab;
  int feedDeck = DateTime.now().microsecondsSinceEpoch;
  int discoverShuffle = DateTime.now().microsecondsSinceEpoch ^ 0x9e3779b9;
  bool browseAll = false;
  final liked = <String>{};
  final saved = <String>{};
  final read = <String>{};
  final visitDays = <String>{};
  final notes = <String, String>{};
  final followed = <Field>{};
  List<Item> _items = const [];
  bool _fromPublished = false;
  List<Item> discoverItems = const [];
  Item? daily;
  bool remote = false;
  bool firebaseReady = false;
  bool contentReady = false;
  bool catalogLoading = false;
  bool feedHasMore = false;
  String? catalogError;
  String? accountError;
  String? accountLabel;
  Map<Field, int> collectionCounts = const {};
  List<AuthorProfile> authors = const [];
  ItemRepository? repository;
  UserDirectory? directory;
  Future<int?> Function(String itemId)? syncView;
  Future<void> Function()? reloadFlags;
  final discoverDeck = DiscoverDeck();

  List<Item> get items =>
      kReleaseMode && !_fromPublished ? const <Item>[] : _items;

  /// Roster people who have no published line yet.
  List<AuthorProfile> get authorsAwaitingLines {
    final quoted = {for (final item in items) personKey(item.author)};
    return authors
        .where((author) => !quoted.contains(personKey(author.name)))
        .toList();
  }

  /// Portrait already stored for this speaker, when the line itself has none.
  AuthorProfile? portraitFor(String name) {
    final key = personKey(name);
    for (final author in authors) {
      final url = author.imageUrl;
      if (personKey(author.name) == key && url != null && url.isNotEmpty) {
        return author;
      }
    }
    return null;
  }

  void debugSeed(List<Item> seeded, {List<AuthorProfile> profiles = const []}) {
    if (kReleaseMode) return;
    _items = seeded;
    authors = profiles;
    _fromPublished = false;
    collectionCounts = {
      for (final field in Field.values)
        field: seeded.where((item) => item.field == field).length,
    };
    notifyListeners();
  }

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
    followSystemTheme = map['followSystemTheme'] as bool? ?? false;
    largeText = map['largeText'] as bool? ?? false;
    onboardingComplete = map['onboardingComplete'] as bool? ?? false;
    usualMood = _mood(map['usualMood'] as String?);
    streak = (map['streak'] as num?)?.toInt() ?? 0;
    lastStreakDate = map['lastStreakDate'] as String?;
    hintDismissed = map['hintDismissed'] as bool? ?? false;
    reminderOn = map['reminderOn'] as bool? ?? false;
    notificationPrefs = NotificationPrefs.fromJson(
      map['notificationPrefs'] is Map
          ? Map<String, dynamic>.from(map['notificationPrefs'] as Map)
          : null,
      legacyReminderTime: map['reminderTime'] as String?,
      legacyReminderOn: reminderOn,
    );
    notificationAskCount =
        (map['notificationAskCount'] as num?)?.toInt() ??
        (map.containsKey('notificationPrefs')
            ? 0
            : reminderOn
            ? 2
            : onboardingComplete
            ? 1
            : 0);
    lastItemViewDate = map['lastItemViewDate'] as String?;
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
    contentLanguage = languageByCode(map['contentLanguage'] as String?)?.code;
    uiLanguage = languageByCode(map['uiLanguage'] as String?)?.code;
    secondLanguage = languageByCode(map['secondLanguage'] as String?)?.code;
    widgetsEnabled = map['widgetsEnabled'] as bool? ?? true;
    showSavedOnLockScreen = map['showSavedOnLockScreen'] as bool? ?? false;
    if (followed.length == 1) collectionFocus = followed.first;
  }

  /// A followed field, the open collection, or a line from one of the quote
  /// lists. Those lists are not tagged with a roster field.
  bool showsInFeed(Item item) =>
      showsField(item.field) || fromQuoteList(item.source.url);

  bool showsField(Field field) {
    if (browseAll) return true;
    if (collectionFocus != null) return field == collectionFocus;
    if (followed.isNotEmpty) return followed.contains(field);
    return true;
  }

  Map<String, Object?> _toJson() => {
    'dark': dark,
    'followSystemTheme': followSystemTheme,
    'largeText': largeText,
    'onboardingComplete': onboardingComplete,
    'usualMood': usualMood?.name,
    'streak': streak,
    'lastStreakDate': lastStreakDate,
    'hintDismissed': hintDismissed,
    'reminderOn': reminderOn,
    'notificationPrefs': notificationPrefs.toJson(),
    'notificationAskCount': notificationAskCount,
    'lastItemViewDate': lastItemViewDate,
    'bestStreak': bestStreak,
    'liked': liked.toList(),
    'saved': saved.toList(),
    'read': read.toList(),
    'visitDays': visitDays.toList(),
    'notes': notes,
    'followed': followed.map((field) => field.name).toList(),
    'contentLanguage': contentLanguage,
    'uiLanguage': uiLanguage,
    'secondLanguage': secondLanguage,
    'widgetsEnabled': widgetsEnabled,
    'showSavedOnLockScreen': showSavedOnLockScreen,
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
    if (on) _maybeAskNotifications();
    _touch();
    directory?.setFlag(collection: 'saved', id: id, on: on);
    syncWidgets();
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
    lastItemViewDate = today;
    noteVisit();
    if (alreadyToday) _touch();
    _syncView(id);
    unawaited(syncNotifications());
  }

  void consumeFeedTarget() {
    feedTarget = null;
  }

  void consumePendingTab() {
    pendingTab = null;
  }

  void reshuffleFeed() {
    feedDeck = DateTime.now().microsecondsSinceEpoch;
    notifyListeners();
  }

  void reshuffleDiscover() {
    discoverShuffle = DateTime.now().microsecondsSinceEpoch;
    notifyListeners();
  }

  void openCollection(Field field) {
    collectionFocus = field;
    browseAll = false;
    pendingTab = AppTab.feed;
    _touch();
  }

  void focusCollection(Field? field) {
    collectionFocus = field;
    browseAll = false;
    _touch();
  }

  void showEverything() {
    collectionFocus = null;
    browseAll = true;
    _touch();
  }

  void toggleFollow(Field field) {
    final on = followed.add(field);
    if (!on) followed.remove(field);
    browseAll = false;
    if (on) {
      collectionFocus = field;
      pendingTab = AppTab.feed;
    } else if (collectionFocus == field) {
      collectionFocus = followed.length == 1 ? followed.first : null;
    }
    _touch();
    directory?.setFlag(collection: 'followedFields', id: field.name, on: on);
    unawaited(syncNotifications());
  }

  void setMood(Mood mood) {
    if (usualMood == mood) return;
    usualMood = mood;
    _touch();
    unawaited(syncNotifications());
  }

  void setDark(bool value) {
    if (dark == value && !followSystemTheme) return;
    dark = value;
    followSystemTheme = false;
    _touch();
  }

  void followSystem(bool systemDark) {
    followSystemTheme = true;
    dark = systemDark;
    _touch();
  }

  void applySystemBrightness(bool systemDark) {
    if (!followSystemTheme || dark == systemDark) return;
    dark = systemDark;
    _touch();
  }

  void setLargeText(bool value) {
    if (largeText == value) return;
    largeText = value;
    _touch();
  }

  /// Null follows the device. Choosing a language sets the app and the
  /// quotes to the same language until the two are changed apart.
  void setContentLanguage(String? code) {
    final next = languageByCode(code)?.code;
    contentLanguage = next;
    uiLanguage = next;
    if (secondLanguage != null && secondLanguage == next) secondLanguage = null;
    _touch();
    _syncLanguages();
    syncWidgets();
    unawaited(syncNotifications());
  }

  void setSecondLanguage(String? code) {
    final next = languageByCode(code)?.code;
    final primary = contentLanguage;
    secondLanguage = next == null || next == primary ? null : next;
    _touch();
    _syncLanguages();
    syncWidgets();
  }

  void setWidgetsEnabled(bool value) {
    if (widgetsEnabled == value) {
      syncWidgets();
      return;
    }
    widgetsEnabled = value;
    _touch();
    syncWidgets();
  }

  void setShowSavedOnLockScreen(bool value) {
    if (showSavedOnLockScreen == value) return;
    showSavedOnLockScreen = value;
    _touch();
    syncWidgets();
  }

  void syncWidgets() {
    final payload = payloadForLibrary(
      items: _items,
      now: DateTime.now(),
      contentLanguage: contentLanguage,
      uiLanguage: uiLanguage,
      device: PlatformDispatcher.instance.locale,
      streakCount: streak,
      lastActiveDate: lastStreakDate,
      savedIds: saved.toList(),
      followed: followed,
      widgetsEnabled: widgetsEnabled,
      showSavedOnLockScreen: showSavedOnLockScreen,
    );
    final source = [for (final item in _items) widgetSourceFromItem(item)];
    unawaited(WidgetSyncService.publish(payload, source: source));
  }

  Future<void> clearWidgets() {
    final device = PlatformDispatcher.instance.locale;
    final content =
        contentLanguage ?? resolveContentLanguage(saved: null, device: device);
    final ui = uiLanguage ?? content;
    return WidgetSyncService.publish(
      widgetPayloadCleared(contentLanguage: content, uiLanguage: ui),
    );
  }

  /// A widget tap. An unknown line opens Home rather than a blank card.
  void openWidgetLink(Uri? uri) {
    final link = WidgetLink.parse(shareWebLinkToApp(uri) ?? uri);
    if (link == null) return;
    final id = link.itemId;
    if (id != null && _items.any((item) => item.id == id)) {
      openInFeed(id);
      return;
    }
    pendingTab = AppTab.home;
    notifyListeners();
  }

  String resolvedContentLanguage(Locale device) {
    return resolveContentLanguage(saved: contentLanguage, device: device);
  }

  List<String> contentFallback(Locale device) {
    return contentLanguageChain(
      primary: resolvedContentLanguage(device),
      second: secondLanguage,
    );
  }

  void _syncLanguages() {
    final directory = this.directory;
    if (directory == null) return;
    directory
        .setLanguages(
          contentLanguage: contentLanguage,
          uiLanguage: uiLanguage,
          secondLanguage: secondLanguage,
        )
        .catchError((_) {});
  }

  Future<bool> sendFeedback(String topic, String message) async {
    final directory = this.directory;
    if (directory == null) return false;
    try {
      await directory.feedback(topic: topic, message: message);
      return true;
    } on Exception {
      return false;
    }
  }

  /// Lines in the library the reader has marked as read.
  int get readInLibrary => items.where((item) => read.contains(item.id)).length;

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

  bool get viewedToday => lastItemViewDate == dayKey(DateTime.now());

  void applyNotificationFlags({required bool enabled, required int maxPerDay}) {
    notificationsEnabled = enabled;
    maxNotificationsPerDay = maxPerDay.clamp(0, maxNotificationsPerDayHardCap);
  }

  void setNotificationPrefs(NotificationPrefs next) {
    notificationPrefs = next;
    reminderOn = next.anyEnabled;
    _touch();
    _publishProfile();
    unawaited(syncNotifications());
  }

  Future<void> enableNotifications() async {
    final ok = await NotificationService.instance.requestPermission();
    notificationPermissionGranted = ok;
    notificationAskCount = 2;
    notificationAskPending = false;
    reminderOn = ok && notificationPrefs.anyEnabled;
    _touch();
    _publishProfile();
    unawaited(syncNotifications());
  }

  void dismissNotificationAsk() {
    notificationAskCount = notificationAskCount >= 1 ? 2 : 1;
    notificationAskPending = false;
    _touch();
  }

  void _maybeAskNotifications() {
    if (notificationAskCount != 1) return;
    if (notificationPermissionGranted) return;
    notificationAskPending = true;
  }

  Future<void> syncNotifications() async {
    final result = await NotificationService.instance.rebuild(
      prefs: notificationPrefs,
      items: items,
      followed: followed,
      seenIds: read,
      streak: streak,
      viewedToday: viewedToday,
      language: contentLanguage ?? 'en',
      uiLanguage: uiLanguage ?? contentLanguage ?? 'en',
      usualMood: usualMood,
      notificationsEnabled: notificationsEnabled,
      maxPerDay: maxNotificationsPerDay,
    );
    notificationPermissionGranted = result.granted;
    if (result.prefs.timeZone != notificationPrefs.timeZone) {
      notificationPrefs = result.prefs;
    }
    notificationPlan = result.plan;
    notifyListeners();
  }

  /// Fires two banners from published lines so lock-screen shots are possible.
  /// Never invents a quote. Returns how many were shown.
  Future<int> previewNotifications() async {
    if (!notificationPermissionGranted) {
      await enableNotifications();
    }
    final lang = uiLanguage ?? contentLanguage ?? 'en';
    final picks = dailyPicks(DateTime.now(), usualMood, items);
    final chosen = <Item>[];
    if (picks != null) {
      chosen.add(picks.quote);
      if (picks.speech != null && picks.speech!.id != picks.quote.id) {
        chosen.add(picks.speech!);
      } else if (picks.boost.id != picks.quote.id) {
        chosen.add(picks.boost);
      }
    }
    for (final item in items) {
      if (chosen.length >= 2) break;
      if (chosen.any((entry) => entry.id == item.id)) continue;
      chosen.add(item);
    }
    if (chosen.isEmpty) return 0;
    final service = NotificationService.instance;
    await service.showNow(
      id: 91001,
      title: morningTitle(lang, 0),
      body: notificationBody(chosen.first.text, chosen.first.author),
      payload: 'motiscroll://item/${chosen.first.id}',
      uiLang: lang,
    );
    if (chosen.length == 1) return 1;
    await service.showIn(
      id: 91002,
      title: eveningTitle(lang, 0),
      body: notificationBody(chosen[1].text, chosen[1].author),
      payload: 'motiscroll://item/${chosen[1].id}',
      uiLang: lang,
      delay: const Duration(seconds: 12),
    );
    return 2;
  }

  Future<void> clearNotifications({bool clearPrefs = false}) async {
    await NotificationService.instance.clearLocalPlan();
    notificationPlan = const [];
    notificationPermissionGranted = false;
    if (clearPrefs) {
      notificationPrefs = const NotificationPrefs();
      reminderOn = false;
    }
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
    if (streak >= 2) _maybeAskNotifications();
    _touch();
    syncWidgets();
  }

  void completeOnboarding({required Set<Field> fields, required Mood? mood}) {
    followed
      ..clear()
      ..addAll(fields);
    collectionFocus = fields.length == 1 ? fields.first : null;
    browseAll = false;
    usualMood = mood;
    onboardingComplete = true;
    _touch();
    _publishProfile();
    syncWidgets();
    unawaited(syncNotifications());
  }

  Future<void> refreshCatalog() async {
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    final repository = this.repository;
    if (repository == null) {
      _ensureLines();
      catalogLoading = false;
      catalogError = _items.isEmpty
          ? (accountError ?? 'Nothing is published yet.')
          : null;
      syncWidgets();
      notifyListeners();
      return;
    }
    try {
      final page = await repository.page();
      _items = page.items;
      _fromPublished = true;
      feedHasMore = page.items.length >= catalogPageSize;
      catalogError = page.items.isEmpty ? 'Nothing is published yet.' : null;
    } on Exception catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'catalog',
          context: ErrorDescription('while opening the library'),
        ),
      );
      _ensureLines();
      catalogLoading = false;
      catalogError = _items.isEmpty ? libraryFailure(error) : null;
      syncWidgets();
      notifyListeners();
      return;
    }
    try {
      discoverItems = (await repository.discover(
        followed: followed,
        deck: discoverDeck,
      )).items;
      if (discoverItems.isEmpty) discoverItems = _items;
    } on Exception catch (error, stack) {
      discoverItems = _items;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'catalog',
          context: ErrorDescription('while opening discover'),
        ),
      );
    }
    try {
      daily = await repository.quoteOfDay(DateTime.now());
    } on Exception catch (error, stack) {
      daily = _items.isEmpty ? null : _items.first;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'catalog',
          context: ErrorDescription('while opening the daily line'),
        ),
      );
    }
    try {
      collectionCounts = await repository.collectionCounts();
    } on Exception catch (error, stack) {
      collectionCounts = {
        for (final field in Field.values)
          field: _items.where((item) => item.field == field).length,
      };
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'catalog',
          context: ErrorDescription('while counting collections'),
        ),
      );
    }
    try {
      authors = await repository.authors();
    } on Exception catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'catalog',
          context: ErrorDescription('while opening the author roster'),
        ),
      );
    }
    _ensureLines();
    catalogLoading = false;
    catalogError = _items.isEmpty ? catalogError : null;
    syncWidgets();
    unawaited(syncNotifications());
    notifyListeners();
  }

  /// Keeps quotes on screen when the remote library is missing or over quota.
  void _ensureLines() {
    if (authors.isEmpty && rosterLines.isNotEmpty) {
      authors = [for (final line in rosterLines) _profileFromLine(line)];
    }
    _applyRosterLines();
    if (_items.isEmpty) return;
    _fromPublished = true;
    if (discoverItems.isEmpty) discoverItems = _items;
  }

  AuthorProfile _profileFromLine(RosterLine line) {
    final url = line.imageUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return AuthorProfile(
      id: 'roster-${personKey(line.name)}',
      name: line.name,
      role: '',
      field: Field.other,
      imageUrl: hasPhoto ? url : null,
      imageCredit: hasPhoto
          ? ImageCredit(
              artist: line.artist,
              license: line.license,
              sourceUrl: line.sourceUrl,
            )
          : null,
    );
  }

  /// Lines and portraits for roster people the published library does not
  /// have yet. The quotes are the ones BrainyQuote lists under that name.
  /// The portraits are allowed Wikimedia files.
  void _applyRosterLines() {
    if (rosterLines.isEmpty || authors.isEmpty) return;
    final have = {for (final item in _items) personKey(item.author)};
    final added = <Item>[];
    authors = [for (final author in authors) _authorWithLine(author)];
    for (final author in authors) {
      final line = rosterLineByKey[personKey(author.name)];
      if (line == null || line.quotes.isEmpty) continue;
      if (have.contains(personKey(author.name))) continue;
      final hasNewPhoto = line.imageUrl != null && line.imageUrl!.isNotEmpty;
      final credit = hasNewPhoto
          ? ImageCredit(
              artist: line.artist,
              license: line.license,
              sourceUrl: line.sourceUrl,
            )
          : author.imageCredit;
      final image = hasNewPhoto ? line.imageUrl : author.imageUrl;
      for (var i = 0; i < line.quotes.length; i++) {
        added.add(
          Item(
            id: 'gap-${personKey(author.name)}-$i',
            type: 'quote',
            text: line.quotes[i],
            author: author.name,
            authorRole: author.role,
            field: author.field,
            moods: const [],
            source: Source(
              title: line.sourceTitle.isEmpty
                  ? 'BrainyQuote'
                  : line.sourceTitle,
              url: line.quoteUrl.isEmpty
                  ? 'https://www.brainyquote.com/authors/${_quoteSlug(author.name)}-quotes'
                  : line.quoteUrl,
            ),
            verified: true,
            deeper: Deeper(
              context: line.context,
              didYouKnow: '',
              takeaway: '',
              related: const [],
            ),
            imageUrl: image,
            imageCredit: credit,
          ),
        );
      }
    }
    if (added.isNotEmpty) _items = [..._items, ...added];
  }

  AuthorProfile _authorWithLine(AuthorProfile author) {
    final line = rosterLineByKey[personKey(author.name)];
    final url = line?.imageUrl;
    if (line == null || url == null || url.isEmpty) return author;
    if (author.imageUrl != null && author.imageUrl!.isNotEmpty) return author;
    return AuthorProfile(
      id: author.id,
      name: author.name,
      role: author.role,
      field: author.field,
      bornYear: author.bornYear,
      diedYear: author.diedYear,
      isLiving: author.isLiving,
      imageUrl: url,
      imageCredit: ImageCredit(
        artist: line.artist,
        license: line.license,
        sourceUrl: line.sourceUrl,
      ),
    );
  }

  Future<void> loadMore() async {
    final repository = this.repository;
    if (!remote || catalogLoading || !feedHasMore || repository == null) return;
    catalogLoading = true;
    notifyListeners();
    try {
      final page = await repository.page(more: true);
      final known = items.map((item) => item.id).toSet();
      _items = [
        ..._items,
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
    lastItemViewDate = dayKey(DateTime.now());
    noteVisit();
    _syncView(id);
    unawaited(syncNotifications());
  }

  void _syncView(String id) {
    final sync = syncView;
    if (sync == null) return;
    sync(id)
        .then((value) {
          if (value == null || value == streak) return;
          streak = value;
          if (streak > bestStreak) bestStreak = streak;
          _touch();
        })
        .catchError((Object _) {
          // A failed view ping must not stop the feed.
          return null;
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
      notificationPrefs = notificationPrefs.copyWith(timeZone: zone);
      await directory.ensureProfile(
        fields: followed,
        mood: usualMood,
        timezone: zone,
        notifications: notificationPrefs.toFirestore(usualMood),
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
    lastItemViewDate = null;
    _touch();
    syncWidgets();
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
