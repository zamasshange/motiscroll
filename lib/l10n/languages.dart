import 'package:flutter/widgets.dart';

import 'country_languages.dart';

/// A language the picker can offer. Tier 1 only. More languages stay off
/// until a reviewed translation of the library exists.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
    required this.direction,
  });

  final String code;
  final String nativeName;
  final String englishName;

  /// Country flag used as the language mark in Settings. A language is not
  /// a country; the flag is the familiar mark for that language in a list.
  final String flag;
  final TextDirection direction;

  bool get rtl => direction == TextDirection.rtl;
}

const appLanguages = <AppLanguage>[
  AppLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    flag: '🇬🇧',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
    flag: '🇪🇸',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
    flag: '🇫🇷',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    flag: '🇵🇹',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
    flag: '🇩🇪',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'it',
    nativeName: 'Italiano',
    englishName: 'Italian',
    flag: '🇮🇹',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'ru',
    nativeName: 'Русский',
    englishName: 'Russian',
    flag: '🇷🇺',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'ar',
    nativeName: 'العربية',
    englishName: 'Arabic',
    flag: '🇸🇦',
    direction: TextDirection.rtl,
  ),
  AppLanguage(
    code: 'fa',
    nativeName: 'فارسی',
    englishName: 'Persian',
    flag: '🇮🇷',
    direction: TextDirection.rtl,
  ),
  AppLanguage(
    code: 'tr',
    nativeName: 'Türkçe',
    englishName: 'Turkish',
    flag: '🇹🇷',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    flag: '🇮🇳',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'id',
    nativeName: 'Bahasa Indonesia',
    englishName: 'Indonesian',
    flag: '🇮🇩',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'zh',
    nativeName: '中文',
    englishName: 'Chinese (Simplified)',
    flag: '🇨🇳',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    flag: '🇯🇵',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'ko',
    nativeName: '한국어',
    englishName: 'Korean',
    flag: '🇰🇷',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'sw',
    nativeName: 'Kiswahili',
    englishName: 'Swahili',
    flag: '🇹🇿',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'af',
    nativeName: 'Afrikaans',
    englishName: 'Afrikaans',
    flag: '🇿🇦',
    direction: TextDirection.ltr,
  ),
  AppLanguage(
    code: 'zu',
    nativeName: 'isiZulu',
    englishName: 'Zulu',
    flag: '🇿🇦',
    direction: TextDirection.ltr,
  ),
];

AppLanguage? languageByCode(String? code) {
  if (code == null || code.isEmpty) return null;
  final bare = code.split(RegExp(r'[-_]')).first.toLowerCase();
  for (final language in appLanguages) {
    if (language.code == bare) return language;
  }
  return null;
}

/// Languages CLDR associates with a country, Tier 1 only, primary first.
List<String> languagesForCountry(String? countryCode) {
  if (countryCode == null || countryCode.isEmpty) return const [];
  return countryLanguageMap[countryCode.toUpperCase()] ?? const [];
}

/// Saved choice, then the device language, then a CLDR country hint, then English.
String resolveContentLanguage({String? saved, required Locale device}) {
  final chosen = languageByCode(saved);
  if (chosen != null) return chosen.code;
  if (_deviceSpeaks(device)) return device.languageCode.toLowerCase();
  final hinted = languagesForCountry(device.countryCode);
  if (hinted.isNotEmpty) return hinted.first;
  return 'en';
}

/// Your language, then the backup language, then English.
List<String> contentLanguageChain({
  required String primary,
  String? second,
}) {
  final chain = <String>[];
  void add(String? code) {
    final language = languageByCode(code);
    if (language == null || chain.contains(language.code)) return;
    chain.add(language.code);
  }

  add(primary);
  add(second);
  add('en');
  return chain;
}

/// Picker order: languages CLDR ties to the device country, then the rest.
List<AppLanguage> languagesForPicker(Locale device) {
  final hinted = languagesForCountry(device.countryCode).toSet();
  final first = <AppLanguage>[];
  final rest = <AppLanguage>[];
  for (final language in appLanguages) {
    if (hinted.contains(language.code)) {
      first.add(language);
    } else {
      rest.add(language);
    }
  }
  final ordered = languagesForCountry(device.countryCode);
  first.sort(
    (a, b) => ordered.indexOf(a.code).compareTo(ordered.indexOf(b.code)),
  );
  return [...first, ...rest];
}

bool _deviceSpeaks(Locale device) {
  final code = device.languageCode.toLowerCase();
  if (languageByCode(code) == null) return false;
  if (code == 'zh') {
    final script = device.scriptCode;
    return script == null || script.toLowerCase() == 'hans';
  }
  return true;
}
