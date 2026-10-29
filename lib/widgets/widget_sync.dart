import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/models.dart';
import '../l10n/languages.dart';
import 'widget_payload.dart';

const _portraits = MethodChannel('motiscroll/portraits');

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
      await HomeWidget.saveWidgetData<String>(
        widgetPayloadKey,
        payload.encode(),
      );
      await _update('QuoteWidgetProvider', 'MotiQuoteWidget');
      await _update('StreakWidgetProvider', 'MotiStreakWidget');
      await _update('SavedWidgetProvider', 'MotiSavedWidget');
      await _update('PoolWidgetProvider', 'MotiPoolWidget');
      if (source != null) {
        await _savePortraits(source);
      }
    } on Object {
      return;
    }
  }

  /// The widget extension never talks to the network. Portraits are written
  /// into the App Group here, and the widget reads the file or draws the mark.
  static Future<void> _savePortraits(List<WidgetSource> source) async {
    if (kIsWeb || Platform.environment['FLUTTER_TEST'] == 'true') return;
    final seen = <String>{};
    var saved = 0;
    for (final item in source) {
      if (saved >= 40) break;
      final url = item.imageUrl;
      if (url == null || url.isEmpty || !seen.add(item.id)) continue;
      final bytes = await _download(url);
      if (bytes == null || bytes.isEmpty) continue;
      try {
        final ok = await _portraits.invokeMethod<bool>('save', {
          'name': widgetPortraitName(item.id),
          'bytes': bytes,
        });
        if (ok == true) saved += 1;
      } on Object {
        return;
      }
    }
    if (saved == 0) return;
    await _update('QuoteWidgetProvider', 'MotiQuoteWidget');
    await _update('StreakWidgetProvider', 'MotiStreakWidget');
    await _update('SavedWidgetProvider', 'MotiSavedWidget');
    await _update('PoolWidgetProvider', 'MotiPoolWidget');
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final client = HttpClient();
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'MotiScroll/1.0 (educational app; freely licensed Wikimedia portraits)',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 6),
      );
      if (response.statusCode != 200) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } on Object {
      return null;
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
  final content =
      contentLanguage ?? resolveContentLanguage(saved: null, device: device);
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
