import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/notifications/notification_prefs.dart';
import 'package:moti_scroll/notifications/notification_service.dart';
import 'package:moti_scroll/state/app_state.dart';
import 'package:moti_scroll/widgets/widget_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/ui_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cold and warm payloads parse the item id', () {
    final uri = notificationPayloadUri(
      'motiscroll://item/fixture-quote?slot=morning&date=2026-10-29',
    );
    final link = WidgetLink.parse(uri);
    expect(link?.itemId, 'fixture-quote');
    expect(WidgetLink.parse(Uri.parse('motiscroll://item/missing'))?.itemId, 'missing');
    expect(WidgetLink.parse(Uri.parse('motiscroll://home'))?.itemId, isNull);
  });

  test('opening a missing item from a notification goes to Home', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.debugSeed(uiFixture());
    state.openWidgetLink(Uri.parse('motiscroll://item/gone'));
    expect(state.pendingTab, isNotNull);
    expect(state.feedTarget, isNull);
  });

  test('opening a known item from a notification records a view', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.debugSeed(uiFixture());
    state.openWidgetLink(Uri.parse('motiscroll://item/fixture-quote'));
    expect(state.feedTarget, 'fixture-quote');
    expect(state.viewedToday, isTrue);
  });

  test('sign-out cleanup cancels the local plan flag', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.notificationPrefs = const NotificationPrefs(morningEnabled: true);
    await state.clearNotifications();
    expect(state.notificationPlan, isEmpty);
    expect(state.notificationPermissionGranted, isFalse);
  });

  test('delete-account cleanup also resets prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.setNotificationPrefs(
      const NotificationPrefs(morningTime: '07:15', eveningEnabled: false),
    );
    await state.clearNotifications(clearPrefs: true);
    expect(state.notificationPrefs.morningTime, '09:30');
    expect(state.notificationPrefs.eveningEnabled, isTrue);
  });

  test('legacy reminderTime migrates onto morningTime', () async {
    SharedPreferences.setMockInitialValues({
      'moti-scroll-state':
          '{"onboardingComplete":true,"reminderOn":true,"reminderTime":"08:00"}',
    });
    final state = AppState();
    await state.load();
    expect(state.notificationPrefs.morningTime, '08:00');
    expect(state.notificationPrefs.eveningTime, '20:30');
  });

  test('Not now is remembered so the third ask never happens', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    expect(state.notificationAskCount, 0);
    state.dismissNotificationAsk();
    expect(state.notificationAskCount, 1);
    state.dismissNotificationAsk();
    expect(state.notificationAskCount, 2);
    state.notificationAskCount = 2;
    state.notificationAskPending = false;
    state.toggleSave('fixture-quote');
    expect(state.notificationAskPending, isFalse);
  });
}
