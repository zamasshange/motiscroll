import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/l10n/widget_gallery.dart';
import 'package:moti_scroll/share/quote_card.dart';
import 'package:moti_scroll/share/share_caption.dart';
import 'package:moti_scroll/share/share_config.dart';
import 'package:moti_scroll/share/share_destinations.dart';
import 'package:moti_scroll/share/share_prefs.dart';
import 'package:moti_scroll/share/share_text.dart';
import 'package:moti_scroll/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/ui_fixture.dart';

Item _item({
  String id = 'share-quote',
  String text = 'A fixture line for the share tests.',
  String author = 'Fixture',
  String title = 'Test source',
  int? year = 2000,
  bool translated = false,
}) {
  return Item(
    id: id,
    type: 'quote',
    text: text,
    author: author,
    authorRole: 'Test',
    field: Field.leadership,
    moods: const [Mood.needFocus],
    source: Source(title: title, year: year),
    verified: true,
    isTranslated: translated,
    deeper: const Deeper(
      context: 'Fixture context',
      didYouKnow: 'Fixture note',
      takeaway: 'Fixture takeaway',
      related: [],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('share strings exist in every supported language', () {
    expect(shareStringsCoverLanguages(), isTrue);
    for (final code in widgetLanguageCodes) {
      expect(shareUi(code, 'share'), isNotEmpty);
      expect(shareUi(code, 'whatsappHint'), isNotEmpty);
    }
  });

  test('caption keeps the exact quote and the placeholder link', () {
    final item = _item(text: 'Begin again without cutting this line.');
    final caption = shareCaption(item);
    expect(caption, contains('"Begin again without cutting this line."'));
    expect(caption, contains('— Fixture'));
    expect(caption, contains('Shared from MotiScroll'));
    expect(caption, contains('https://example.com/motiscroll/q/share-quote'));
    expect(caption.contains('...'), isFalse);
  });

  test('web share links map onto the app scheme', () {
    expect(
      shareWebLinkToApp(
        Uri.parse('https://example.com/motiscroll/q/fixture-quote'),
      ),
      Uri.parse('motiscroll://item/fixture-quote'),
    );
    expect(
      shareWebLinkToApp(Uri.parse('motiscroll://item/fixture-quote')),
      Uri.parse('motiscroll://item/fixture-quote'),
    );
    expect(shareItemLink('abc'), 'https://example.com/motiscroll/q/abc');
  });

  test('opening a web share link records the same feed target', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.debugSeed(uiFixture());
    state.openWidgetLink(
      Uri.parse('https://example.com/motiscroll/q/fixture-quote'),
    );
    expect(state.feedTarget, 'fixture-quote');
  });

  test('cache keys differ by template, format, and language', () {
    expect(
      shareCacheKey(
        itemId: 'a',
        template: ShareTemplate.dark,
        format: ShareFormat.story,
        language: 'en',
      ),
      isNot(
        shareCacheKey(
          itemId: 'a',
          template: ShareTemplate.light,
          format: ShareFormat.story,
          language: 'en',
        ),
      ),
    );
    expect(
      shareCacheKey(
        itemId: 'a',
        template: ShareTemplate.dark,
        format: ShareFormat.square,
        language: 'ar',
      ),
      'a/dark/square/ar',
    );
  });

  test('auto-fit never truncates and grows a short line', () {
    const short = 'Begin.';
    const long =
        'word word word word word word word word word word '
        'word word word word word word word word word word '
        'word word word word word word word word word word '
        'word word word word word word word word word word';
    expect(long.split(' ').length, 40);
    final shortFit = fitQuoteFont(
      text: short,
      direction: TextDirection.ltr,
      language: 'en',
      maxWidth: 952,
      maxHeight: 1048,
      minSize: shareQuoteFontMin,
      maxSize: shareQuoteFontMaxStory,
    );
    final longFit = fitQuoteFont(
      text: long,
      direction: TextDirection.ltr,
      language: 'en',
      maxWidth: 952,
      maxHeight: 1048,
      minSize: shareQuoteFontMin,
      maxSize: shareQuoteFontMaxStory,
    );
    expect(shortFit.fontSize, greaterThan(longFit.fontSize));
    expect(longFit.fontSize, greaterThanOrEqualTo(shareQuoteFontMin));
    expect(shortFit.tall, isFalse);
    expect(longFit.tall, isFalse);

    final squeezed = fitQuoteFont(
      text: 'A' * 400,
      direction: TextDirection.ltr,
      language: 'en',
      maxWidth: 200,
      maxHeight: 60,
      minSize: shareQuoteFontMin,
      maxSize: shareQuoteFontMaxStory,
    );
    expect(squeezed.tall, isTrue);
    expect(squeezed.fontSize, shareQuoteFontMin);
  });

  test('destination buttons stay available without META_APP_ID', () {
    const none = ShareApps();
    const all = ShareApps(
      instagram: true,
      facebook: true,
      facebookLite: true,
      whatsapp: true,
      whatsappBusiness: false,
    );
    expect(instagramStoryView(none, metaReady: false).visible, isTrue);
    expect(facebookView(none, metaReady: false).visible, isTrue);
    expect(instagramStoryView(all, metaReady: false).visible, isTrue);
    expect(instagramStoryView(all, metaReady: false).systemShare, isTrue);
    expect(facebookView(all, metaReady: false).systemShare, isTrue);

    final dimIg = instagramStoryView(none, metaReady: true);
    expect(dimIg.visible, isTrue);
    expect(dimIg.enabled, isTrue);
    expect(dimIg.systemShare, isTrue);

    final liveIg = instagramStoryView(all, metaReady: true);
    expect(liveIg.enabled, isTrue);
    expect(liveIg.systemShare, isFalse);

    final liteOnly = facebookView(
      const ShareApps(facebookLite: true),
      metaReady: true,
    );
    expect(liteOnly.enabled, isTrue);
    expect(liteOnly.systemShare, isTrue);

    expect(whatsappView(none).enabled, isTrue);
    expect(whatsappView(none).systemShare, isTrue);
    expect(whatsappView(all).enabled, isTrue);
    expect(whatsappView(ShareApps.unknown).enabled, isTrue);
    expect(whatsappView(ShareApps.unknown).systemShare, isTrue);
    expect(metaAppIdReady, isFalse);
    expect(
      formatForDestination(ShareDestination.instagramStory),
      ShareFormat.story,
    );
    expect(formatForDestination(ShareDestination.whatsapp), ShareFormat.square);
  });
}
