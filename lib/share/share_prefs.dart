import 'package:shared_preferences/shared_preferences.dart';

import 'quote_card.dart';
import 'share_destinations.dart';

class SharePrefs {
  static const _templateKey = 'share_template_v1';
  static const _formatKey = 'share_format_v1';
  static const _destinationKey = 'share_destination_v1';
  static const _whatsAppHintKey = 'share_whatsapp_hint_v1';

  static Future<ShareSessionPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ShareSessionPrefs(
      template: templateFromName(prefs.getString(_templateKey)),
      format: formatFromName(prefs.getString(_formatKey)),
      destination: destinationFromName(prefs.getString(_destinationKey)),
      whatsAppHintShown: prefs.getBool(_whatsAppHintKey) ?? false,
    );
  }

  static Future<void> setTemplate(ShareTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templateKey, template.name);
  }

  static Future<void> setFormat(ShareFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formatKey, format.name);
  }

  static Future<void> setDestination(ShareDestination destination) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_destinationKey, destination.name);
  }

  static Future<void> setWhatsAppHintShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_whatsAppHintKey, true);
  }
}

class ShareSessionPrefs {
  const ShareSessionPrefs({
    required this.template,
    required this.format,
    required this.destination,
    required this.whatsAppHintShown,
  });

  final ShareTemplate template;
  final ShareFormat? format;
  final ShareDestination? destination;
  final bool whatsAppHintShown;
}

ShareTemplate templateFromName(String? name) {
  for (final value in ShareTemplate.values) {
    if (value.name == name) return value;
  }
  return ShareTemplate.dark;
}

ShareFormat? formatFromName(String? name) {
  for (final value in ShareFormat.values) {
    if (value.name == name) return value;
  }
  return null;
}

ShareDestination? destinationFromName(String? name) {
  for (final value in ShareDestination.values) {
    if (value.name == name) return value;
  }
  return null;
}

ShareFormat formatForDestination(ShareDestination? destination) {
  return switch (destination) {
    ShareDestination.instagramStory || ShareDestination.facebook =>
      ShareFormat.story,
    _ => ShareFormat.square,
  };
}
