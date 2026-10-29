import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_planner.dart';
import 'notification_prefs.dart';

class NotificationStore {
  const NotificationStore();

  Future<List<PlannedNotification>> loadPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(notificationPlanKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final row in decoded)
          if (row is Map<String, dynamic>) PlannedNotification.fromJson(row)
          else if (row is Map)
            PlannedNotification.fromJson(Map<String, dynamic>.from(row)),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> savePlan(List<PlannedNotification> plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        notificationPlanKey,
        jsonEncode([for (final row in plan) row.toJson()]),
      );
    } on Object {
      return;
    }
  }

  Future<Map<String, String>> loadNotified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(notificationNotifiedKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries) '${entry.key}': '${entry.value}',
      };
    } on Object {
      return {};
    }
  }

  Future<void> saveNotified(Map<String, String> notifiedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(notificationNotifiedKey, jsonEncode(notifiedAt));
    } on Object {
      return;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(notificationPlanKey);
      await prefs.remove(notificationNotifiedKey);
    } on Object {
      return;
    }
  }
}
