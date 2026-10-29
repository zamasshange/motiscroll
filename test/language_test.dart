import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/l10n/languages.dart';
import 'package:moti_scroll/l10n/ui_text.dart';

void main() {
  test('saved choice wins over the device and the country', () {
    expect(
      resolveContentLanguage(
        saved: 'zu',
        device: const Locale('en', 'ZA'),
      ),
      'zu',
    );
  });

  test('device language is used when nothing is saved', () {
    expect(
      resolveContentLanguage(device: const Locale('fr', 'FR')),
      'fr',
    );
    expect(
      resolveContentLanguage(device: const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      )),
      'zh',
    );
    expect(
      resolveContentLanguage(device: const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'US',
      )),
      'en',
    );
  });

  test('country hint is used only when the device language is unsupported', () {
    expect(languagesForCountry('CH'), containsAll(['fr', 'de', 'it']));
    expect(languagesForCountry('BE'), containsAll(['fr', 'de']));
    expect(languagesForCountry('IN'), ['en', 'hi']);
    expect(languagesForCountry('ZA'), containsAll(['en', 'af', 'zu']));
    expect(languagesForCountry('CA'), containsAll(['en', 'fr']));
    expect(
      resolveContentLanguage(device: const Locale('rm', 'CH')),
      languagesForCountry('CH').first,
    );
    expect(
      resolveContentLanguage(device: const Locale('fr', 'CH')),
      'fr',
    );
  });

  test('fallback is the chosen language, then the backup, then English', () {
    expect(
      contentLanguageChain(primary: 'fa', second: 'fr'),
      ['fa', 'fr', 'en'],
    );
    expect(contentLanguageChain(primary: 'en', second: 'en'), ['en']);
    expect(contentLanguageChain(primary: 'de'), ['de', 'en']);
  });

  test('interface words follow the chosen language', () {
    expect(ui('fr', 'settings'), 'Réglages');
    expect(ui('ar', 'language'), 'اللغة');
    expect(ui('xx', 'home'), 'Home');
  });
}
