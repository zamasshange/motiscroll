import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';
import 'notification_planner.dart';
import 'notification_prefs.dart';
import 'notification_schedule.dart';
import 'notification_store.dart';
import 'notification_text.dart';

/// Retired Phase 2 repeating 8:00 reminder.
const legacyReminderId = 8;

const _iosNotify = MethodChannel('motiscroll/notify');

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationStore? store,
    NotificationPlanner? planner,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _store = store ?? const NotificationStore(),
       _planner = planner ?? const NotificationPlanner();

  static final instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationStore _store;
  final NotificationPlanner _planner;

  void Function(String? payload)? onTap;
  var _ready = false;
  var _zonesReady = false;

  Future<void> prepareZones({String? timeZone}) async {
    if (_zonesReady && timeZone == null) return;
    tzdata.initializeTimeZones();
    var name = timeZone;
    name ??= (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(name));
    _zonesReady = true;
  }

  Future<String> currentTimeZone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object {
      return 'UTC';
    }
  }

  Future<void> initialize() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_motiscroll'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: false,
          defaultPresentBadge: false,
          defaultPresentSound: false,
          defaultPresentBanner: false,
          defaultPresentList: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          onTap?.call(response.payload);
        },
      );
      _ready = true;
    } on Object {
      _ready = false;
    }
  }

  Future<String?> launchPayload() async {
    try {
      await initialize();
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      return details?.notificationResponse?.payload;
    } on Object {
      return null;
    }
  }

  Future<bool> permissionGranted() async {
    try {
      await initialize();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final status = await ios.checkPermissions();
        return status?.isEnabled == true;
      }
      return false;
    } on Object {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      await initialize();
      final pending = _nativeRequestPermission();
      final deadline = DateTime.now().add(const Duration(seconds: 12));
      while (DateTime.now().isBefore(deadline)) {
        final granted = await Future.any<bool?>([
          pending.then<bool?>((value) => value),
          Future<bool?>.delayed(const Duration(milliseconds: 280)),
        ]);
        if (granted != null) return granted;
        if (await permissionGranted()) return true;
      }
      return await permissionGranted();
    } on Object {
      try {
        return await permissionGranted();
      } on Object {
        return false;
      }
    }
  }

  Future<bool> _nativeRequestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosOk = await ios?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );
    final androidOk = await android?.requestNotificationsPermission();
    if (iosOk == false || androidOk == false) return false;
    if (ios == null && android == null) return false;
    return permissionGranted();
  }

  Future<void> openSystemSettings() async {
    try {
      await initialize();
      await _plugin.openAppNotificationSettings();
    } on Object {
      return;
    }
  }

  Future<void> cancelAllScheduled({DateTime? from}) async {
    // [from] is kept so callers can pass a date; we cancel the whole local plan.
    try {
      await initialize();
      await _plugin.cancel(id: legacyReminderId);
      await _plugin.cancelAll();
    } on Object {
      return;
    }
  }

  Future<void> clearLocalPlan() async {
    await cancelAllScheduled();
    await _store.clear();
  }

  Future<NotificationRebuild> rebuild({
    required NotificationPrefs prefs,
    required List<Item> items,
    required Set<Field> followed,
    required Set<String> seenIds,
    required int streak,
    required bool viewedToday,
    required String language,
    required String uiLanguage,
    required Mood? usualMood,
    String? Function(Item item)? portraitOf,
    required bool notificationsEnabled,
    required int maxPerDay,
  }) async {
    try {
      await initialize();
      final granted = await permissionGranted();
      var zone = await currentTimeZone();
      var nextPrefs = prefs;
      if (timezoneChanged(prefs.timeZone, zone) || prefs.timeZone == 'UTC') {
        nextPrefs = prefs.copyWith(timeZone: zone);
      } else {
        zone = prefs.timeZone;
      }
      if (!canScheduleNotifications(
        granted: granted,
        killSwitchOn: notificationsEnabled,
        anySlotEnabled: nextPrefs.anyEnabled,
      )) {
        await cancelAllScheduled();
        await _store.savePlan(const []);
        return NotificationRebuild(
          granted: granted,
          prefs: nextPrefs,
          plan: const [],
        );
      }
      await prepareZones(timeZone: zone);
      final previous = await _store.loadPlan();
      final notified = mergeFiredNotified(
        notifiedAt: await _store.loadNotified(),
        previous: previous,
        now: DateTime.now(),
      );
      await _store.saveNotified(notified);
      final plan = _planner.plan(
        PlannerInput(
          now: DateTime.now(),
          prefs: nextPrefs,
          items: items,
          followed: followed,
          seenIds: seenIds,
          notifiedAt: notified,
          streak: streak,
          viewedToday: viewedToday,
          language: language,
          usualMood: usualMood,
          portraitOf: portraitOf,
          permissionGranted: granted,
          notificationsEnabled: notificationsEnabled,
          maxPerDay: maxPerDay,
        ),
      );
      await cancelAllScheduled();
      final location = tz.getLocation(zone);
      for (final row in plan) {
        await _schedule(row, location, uiLanguage);
      }
      await _store.savePlan(plan);
      return NotificationRebuild(
        granted: granted,
        prefs: nextPrefs,
        plan: plan,
      );
    } on Object {
      return NotificationRebuild(granted: false, prefs: prefs, plan: const []);
    }
  }

  Future<List<PlannedNotification>> loadPlan() => _store.loadPlan();

  NotificationDetails _bannerDetails(
    String uiLang,
    String body, {
    String? imagePath,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'motiscroll_preview',
        notifyUi(uiLang, 'notifications'),
        icon: '@drawable/ic_stat_motiscroll',
        largeIcon: imagePath == null ? null : FilePathAndroidBitmap(imagePath),
        channelShowBadge: false,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        presentBadge: false,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  Future<bool> _showOnIos({
    required int id,
    required String title,
    required String body,
    required String payload,
    int? fireAtMillis,
    String? imagePath,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      await _iosNotify.invokeMethod<void>('show', {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
        'fireAtMillis': fireAtMillis,
        'imagePath': imagePath,
      });
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String uiLang,
    String? imageUrl,
  }) async {
    await initialize();
    final imagePath = await _portraitPath(imageUrl);
    if (await _showOnIos(
      id: id,
      title: title,
      body: body,
      payload: payload,
      imagePath: imagePath,
    )) {
      return;
    }
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: _bannerDetails(uiLang, body, imagePath: imagePath),
    );
  }

  Future<void> showIn({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String uiLang,
    required Duration delay,
    String? imageUrl,
  }) async {
    await initialize();
    await prepareZones();
    final when = tz.TZDateTime.now(tz.local).add(delay);
    final imagePath = await _portraitPath(imageUrl);
    if (await _showOnIos(
      id: id,
      title: title,
      body: body,
      payload: payload,
      fireAtMillis: when.millisecondsSinceEpoch,
      imagePath: imagePath,
    )) {
      return;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: when,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: _bannerDetails(uiLang, body, imagePath: imagePath),
    );
  }

  Future<void> _schedule(
    PlannedNotification row,
    tz.Location location,
    String uiLang,
  ) async {
    final when = zonedWallClock(
      location: location,
      date: DateTime.parse(row.date),
      hour: row.hour,
      minute: row.minute,
    );
    if (!when.isAfter(tz.TZDateTime.now(location))) return;
    final soon = when.difference(tz.TZDateTime.now(location)).inHours < 36;
    final imagePath = soon ? await _portraitPath(row.imageUrl) : null;
    if (await _showOnIos(
      id: row.id,
      title: row.title,
      body: row.body,
      payload: row.payload,
      fireAtMillis: when.millisecondsSinceEpoch,
      imagePath: imagePath,
    )) {
      return;
    }
    await _plugin.zonedSchedule(
      id: row.id,
      title: row.title,
      body: row.body,
      scheduledDate: when,
      payload: row.payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          row.channelId,
          notifyUi(
            uiLang,
            row.slot == NotificationSlot.morning
                ? 'channelMorning'
                : 'channelEvening',
          ),
          channelDescription: notifyUi(
            uiLang,
            row.slot == NotificationSlot.morning
                ? 'channelMorningDetail'
                : 'channelEveningDetail',
          ),
          icon: '@drawable/ic_stat_motiscroll',
          largeIcon: imagePath == null
              ? null
              : FilePathAndroidBitmap(imagePath),
          channelShowBadge: false,
          styleInformation: BigTextStyleInformation(row.body),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentBanner: false,
          presentList: false,
          presentSound: false,
          badgeNumber: 0,
          sound: '',
          threadIdentifier: row.channelId,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
    );
  }

  Future<String?> _portraitPath(String? url) async {
    if (url == null || url.isEmpty || kIsWeb) return null;
    try {
      final client = HttpClient();
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'MotiScroll/1.0 (educational app; freely licensed Wikimedia portraits)',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode != 200) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notify_${url.hashCode.abs()}.jpg');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on Object {
      return null;
    }
  }
}

class NotificationRebuild {
  const NotificationRebuild({
    required this.granted,
    required this.prefs,
    required this.plan,
  });

  final bool granted;
  final NotificationPrefs prefs;
  final List<PlannedNotification> plan;
}

Uri? notificationPayloadUri(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  return Uri.tryParse(payload);
}

Future<void> openSystemNotificationSettings() {
  return NotificationService.instance.openSystemSettings();
}

String formatClockTime(String hhmm, String locale) {
  final clock = parseHHmm(hhmm);
  final dt = DateTime(2020, 1, 1, clock.hour, clock.minute);
  try {
    return DateFormat.jm(locale).format(dt);
  } on Object {
    try {
      return DateFormat.jm().format(dt);
    } on Object {
      return clock.hhmm;
    }
  }
}
