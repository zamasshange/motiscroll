import 'dart:io';

import '../lib/l10n/widget_gallery.dart';

/// Writes widget gallery strings from [widgetGallery].
/// Languages other than English are flagged needs_review.
void main() {
  final android = Directory('android/app/src/main/res');
  final ios = Directory('ios/MotiWidgets');
  for (final code in widgetLanguageCodes) {
    // Android resource qualifiers still use the legacy code `in` for Indonesian.
    final qualifier = code == 'en'
        ? 'values'
        : 'values-${code == 'id' ? 'in' : code}';
    final values = Directory('${android.path}/$qualifier');
    values.createSync(recursive: true);
    final xml = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="utf-8"?>')
      ..writeln('<resources>');
    if (code != 'en') {
      xml.writeln(
        '    <!-- needs_review: machine translation, same standard as the app UI. -->',
      );
    }
    for (final entry in widgetGallery.entries) {
      final value = entry.value[code] ?? entry.value['en']!;
      xml.writeln(
        '    <string name="${entry.key}">${_xml(value)}</string>',
      );
    }
    xml.writeln('</resources>');
    File('${values.path}/strings.xml').writeAsStringSync(xml.toString());

    final lproj = Directory('${ios.path}/$code.lproj');
    lproj.createSync(recursive: true);
    final strings = StringBuffer();
    if (code != 'en') {
      strings.writeln('/* needs_review: machine translation, same standard as the app UI. */');
    }
    for (final entry in widgetGallery.entries) {
      final value = entry.value[code] ?? entry.value['en']!;
      strings.writeln('"${entry.key}" = "${_strings(value)}";');
    }
    File('${lproj.path}/Localizable.strings').writeAsStringSync(strings.toString());
  }
  stdout.writeln('Wrote widget strings for ${widgetLanguageCodes.length} languages.');
}

String _xml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll("'", r"\'")
      .replaceAll('"', '&quot;');
}

String _strings(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
}
