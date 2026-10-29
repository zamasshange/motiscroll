import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/models.dart';
import '../l10n/languages.dart';
import 'widget_payload.dart';

/// Writes the versioned payload into the App Group / HomeWidget preferences.
/// The widget extension never talks to the network. Failures stay quiet so a
/// missing App Group or a test binding cannot take the app down.
class WidgetSyncService {
  static Future<void> publish(
    WidgetPayload payload, {
    List<WidgetSource>? source,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (source != null) {
        final snapshot = widgetSourceSnapshot(source);
        await prefs.setString(
          widgetSourceKey,
          jsonEncode([for (final item in snapshot) item.toJson()]),
        );
      }
      await HomeWidget.setAppGroupId(widgetAppGroup);
      await HomeWidget.saveWidgetData<String>(widgetPayloadKey, payload.encode());
      await _update('QuoteWidgetProvider', 'MotiQuoteWidget');
      await _update('StreakWidgetProvider', 'MotiStreakWidget');
      await _update('SavedWidgetProvider', 'MotiSavedWidget');
      await _update('PoolWidgetProvider', 'MotiPoolWidget');
    } on Object {
      return;
    }
  }

  static Future<void> _update(String androidName, String iOSName) {
    return HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.moti_scroll.$androidName',
      iOSName: iOSName,
    );
  }

  /// Rebuilds from the last catalog snapshot and the saved user blob.
  /// Used when the app is open and from the daily background task.
  static Future<void> refreshFromCache({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = payloadFromStored(
        userJson: prefs.getString(widgetUserStateKey),
        sourceJson: prefs.getString(widgetSourceKey),
        now: now ?? DateTime.now(),
      );
      if (payload == null) {
        await publish(
          widgetPayloadCleared(contentLanguage: 'en', uiLanguage: 'en'),
        );
        return;
      }
      await publish(payload);
    } on Object {
      return;
    }
  }

  static Future<void> registerRefresh() async {
    try {
      await Workmanager().initialize(widgetRefreshDispatcher);
      await Workmanager().registerPeriodicTask(
        widgetRefreshTask,
        widgetRefreshTask,
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } on Object {
      return;
    }
  }
}

@pragma('vm:entry-point')
void widgetRefreshDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await WidgetSyncService.refreshFromCache();
    } on Object {
      return true;
    }
    return true;
  });
}

WidgetPayload payloadForLibrary({
  required List<Item> items,
  required DateTime now,
  required String? contentLanguage,
  required String? uiLanguage,
  required Locale device,
  required int streakCount,
  required String? lastActiveDate,
  required List<String> savedIds,
  required Iterable<Field> followed,
  required bool widgetsEnabled,
  required bool showSavedOnLockScreen,
}) {
  final content = contentLanguage ??
      resolveContentLanguage(saved: null, device: device);
  final ui = uiLanguage ?? content;
  if (!widgetsEnabled) {
    return widgetPayloadDisabled(
      now: now,
      contentLanguage: content,
      uiLanguage: ui,
    );
  }
  return buildWidgetPayload(
    items: [for (final item in items) widgetSourceFromItem(item)],
    now: now,
    contentLanguage: content,
    uiLanguage: ui,
    streakCount: streakCount,
    lastActiveDate: lastActiveDate,
    savedIds: savedIds,
    followedFields: [for (final field in followed) field.name],
    showSavedOnLockScreen: showSavedOnLockScreen,
  );
}
