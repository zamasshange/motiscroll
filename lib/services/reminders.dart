import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const reminderId = 8;

var _timeZonesReady = false;

Future<void> _prepareZones() async {
  if (_timeZonesReady) return;
  tzdata.initializeTimeZones();
  final info = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(info.identifier));
  _timeZonesReady = true;
}

Future<FlutterLocalNotificationsPlugin> _plugin() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await plugin.initialize(settings: settings);
  return plugin;
}

/// Schedules a local 8:00 reminder. Nothing is sent off the device.
Future<bool> scheduleDailyReminder() async {
  try {
    await _prepareZones();
    final plugin = await _plugin();
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = plugin
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

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await plugin.zonedSchedule(
      id: reminderId,
      title: 'Moti Scroll',
      body: 'A line is waiting when you are.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily-line',
          'Daily line',
          channelDescription: 'A local reminder at 8:00.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  } on Exception {
    return false;
  }
}

Future<void> cancelDailyReminder() async {
  try {
    final plugin = await _plugin();
    await plugin.cancel(id: reminderId);
  } on Exception {
    return;
  }
}
