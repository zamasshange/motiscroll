import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/l10n/widget_gallery.dart';
import 'package:moti_scroll/share/quote_card.dart';
import 'package:moti_scroll/share/share_sheet.dart';
import 'package:moti_scroll/share/share_text.dart';
import 'package:moti_scroll/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/ui_fixture.dart';

Item _card({
  String id = 'card-en',
  String text = 'Begin.',
  String author = 'Fixture',
  String title = 'Notes',
  int? year = 1901,
  bool translated = false,
  Field field = Field.leadership,
}) {
  return Item(
    id: id,
    type: 'quote',
    text: text,
    author: author,
    authorRole: 'Test',
    field: field,
    moods: const [Mood.needFocus],
    source: Source(title: title, year: year),
    verified: true,
    isTranslated: translated,
    deeper: const Deeper(
      context: '',
      didYouKnow: '',
      takeaway: '',
      related: [],
    ),
  );
}

const _forty =
    'word word word word word word word word word word '
    'word word word word word word word word word word '
    'word word word word word word word word word word '
    'word word word word word word word word word word';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Playfair', [
    'assets/fonts/PlayfairDisplay_600SemiBold.ttf',
  ]);
  await load('DMSans', [
    'assets/fonts/DMSans_400Regular.ttf',
    'assets/fonts/DMSans_600SemiBold.ttf',
  ]);
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required Item item,
  required ShareTemplate template,
  required ShareFormat format,
  required String language,
  TextScaler scaler = TextScaler.noScaling,
}) async {
  final size = shareFormatSize(format);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: scaler),
      child: MaterialApp(
        home: QuoteCardWidget(
          item: item,
          template: template,
          format: format,
          language: language,
          translatedLabel: widgetString(language, 'translated'),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectInsideSafeZone(WidgetTester tester, ShareFormat format) {
  final card = tester.getRect(find.byType(QuoteCardWidget));
  final safe = shareSafeRect(card.size, format).shift(card.topLeft);
  final keys = [
    find.byKey(const Key('quote-card-quote')),
    find.byKey(const Key('quote-card-author')),
    find.byKey(const Key('quote-card-source')),
    find.byKey(const Key('quote-card-wordmark')),
  ];
  for (final finder in keys) {
    final rect = tester.getRect(finder);
    expect(rect.top, greaterThanOrEqualTo(safe.top - 1), reason: '$finder top');
    expect(
      rect.bottom,
      lessThanOrEqualTo(safe.bottom + 1),
      reason: '$finder bottom',
    );
  }
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  testWidgets('every template and format keeps English text in the safe zone', (
    tester,
  ) async {
    final short = _card();
    final long = _card(id: 'card-40', text: _forty);
    for (final template in ShareTemplate.values) {
      for (final format in ShareFormat.values) {
        for (final item in [short, long]) {
          await _pumpCard(
            tester,
            item: item,
            template: template,
            format: format,
            language: 'en',
          );
          final quote = tester.widget<Text>(
            find.byKey(const Key('quote-card-quote')),
          );
          expect(quote.data, item.text);
          expect(quote.maxLines, isNull);
          expect(find.text('— ${item.author}'), findsOneWidget);
          expect(find.text(item.source.line), findsOneWidget);
          _expectInsideSafeZone(tester, format);
        }
      }
    }
  });

  testWidgets('Arabic, Persian, Russian, Chinese, and Hindi stay in bounds', (
    tester,
  ) async {
    final items = <(String, Item)>[
      (
        'ar',
        _card(
          id: 'card-ar',
          text: 'هذا سطر للتجربة فقط.',
          author: 'Fixture',
        ),
      ),
      (
        'fa',
        _card(
          id: 'card-fa',
          text: 'این یک خط آزمایشی است.',
          author: 'Fixture',
        ),
      ),
      (
        'ru',
        _card(
          id: 'card-ru',
          text: 'Это строка только для проверки.',
        ),
      ),
      (
        'zh',
        _card(
          id: 'card-zh',
          text: '这是一句用于测试的句子。',
        ),
      ),
      (
        'hi',
        _card(
          id: 'card-hi',
          text: 'यह परीक्षण के लिए एक पंक्ति है।',
        ),
      ),
    ];
    for (final entry in items) {
      await _pumpCard(
        tester,
        item: entry.$2,
        template: ShareTemplate.dark,
        format: ShareFormat.story,
        language: entry.$1,
      );
      final quote = tester.widget<Text>(
        find.byKey(const Key('quote-card-quote')),
      );
      expect(quote.data, entry.$2.text);
      _expectInsideSafeZone(tester, ShareFormat.story);
    }
  });

  testWidgets('translated label, long names, and large text scale', (
    tester,
  ) async {
    final item = _card(
      id: 'card-meta',
      text: 'Begin.',
      author: 'A Very Long Author Name With Many Particles von Something',
      title:
          'The Complete Collected Public Addresses of a Very Long Title',
      translated: true,
    );
    await _pumpCard(
      tester,
      item: item,
      template: ShareTemplate.dark,
      format: ShareFormat.story,
      language: 'en',
      scaler: const TextScaler.linear(2),
    );
    expect(find.byKey(const Key('quote-card-translated')), findsOneWidget);
    expect(find.text('Translated'), findsOneWidget);
    _expectInsideSafeZone(tester, ShareFormat.story);
    final scaled = tester
        .widget<Text>(find.byKey(const Key('quote-card-quote')))
        .style!
        .fontSize;
    await _pumpCard(
      tester,
      item: item,
      template: ShareTemplate.dark,
      format: ShareFormat.story,
      language: 'en',
    );
    final unscaled = tester
        .widget<Text>(find.byKey(const Key('quote-card-quote')))
        .style!
        .fontSize;
    expect(scaled, unscaled);
  });

  testWidgets('goldens for templates, formats, and scripts', (tester) async {
    Future<void> golden({
      required String name,
      required Item item,
      required ShareTemplate template,
      required ShareFormat format,
      required String language,
    }) async {
      final size = shareFormatSize(format);
      final preview = Size(size.width / 4, size.height / 4);
      tester.view.physicalSize = preview;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ColoredBox(
            color: const Color(0xFF000000),
            child: Center(
              child: SizedBox(
                key: const Key('golden-preview'),
                width: preview.width,
                height: preview.height,
                child: FittedBox(
                  child: QuoteCardWidget(
                    item: item,
                    template: template,
                    format: format,
                    language: language,
                    translatedLabel: widgetString(language, 'translated'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(const Key('golden-preview')),
        matchesGoldenFile('goldens/$name.png'),
      );
    }

    await golden(
      name: 'dark_story_en_short',
      item: _card(),
      template: ShareTemplate.dark,
      format: ShareFormat.story,
      language: 'en',
    );
    await golden(
      name: 'light_portrait_en_40',
      item: _card(id: 'card-40', text: _forty),
      template: ShareTemplate.light,
      format: ShareFormat.portrait,
      language: 'en',
    );
    await golden(
      name: 'cover_square_en',
      item: _card(id: 'card-cover'),
      template: ShareTemplate.cover,
      format: ShareFormat.square,
      language: 'en',
    );
    await golden(
      name: 'minimal_story_en',
      item: _card(id: 'card-min'),
      template: ShareTemplate.minimal,
      format: ShareFormat.story,
      language: 'en',
    );
    await golden(
      name: 'dark_story_ru',
      item: _card(id: 'card-ru', text: 'Это строка только для проверки.'),
      template: ShareTemplate.dark,
      format: ShareFormat.story,
      language: 'ru',
    );
    await golden(
      name: 'dark_story_en_translated',
      item: _card(id: 'card-tr', translated: true),
      template: ShareTemplate.dark,
      format: ShareFormat.story,
      language: 'en',
    );
  });

  testWidgets('share sheet uses RTL for Arabic and Persian UI', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final lang in ['ar', 'fa']) {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.load();
      state.debugSeed(uiFixture());
      state.contentLanguage = lang;
      state.uiLanguage = lang;
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            home: Scaffold(
              body: ShareSheet(item: uiFixture().first),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(shareUi(lang, 'share')), findsOneWidget);
      expect(find.text(shareUi(lang, 'whatsapp')), findsOneWidget);
      expect(find.text(shareUi(lang, 'more')), findsOneWidget);
      expect(find.text(shareUi('en', 'instagramStory')), findsNothing);
      final direction = tester.widget<Directionality>(
        find
            .descendant(
              of: find.byType(ShareSheet),
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(direction.textDirection, TextDirection.rtl, reason: lang);
    }
  });
}
