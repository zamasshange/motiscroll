import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../data/models.dart';
import '../l10n/languages.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';

const shareStoryWidth = 1080.0;
const shareStoryHeight = 1920.0;
const sharePortraitHeight = 1350.0;
const shareSquareHeight = 1080.0;

const shareStorySafeTop = 0.14;
const shareStorySafeBottom = 0.20;
const shareOtherSafeTop = 0.08;
const shareOtherSafeBottom = 0.12;

const shareQuoteFontMin = 22.0;
const shareQuoteFontMaxStory = 72.0;
const shareQuoteFontMaxPortrait = 58.0;
const shareQuoteFontMaxSquare = 48.0;

const shareMaxPngBytes = 5 * 1024 * 1024;

/// Physical pixels per logical pixel when writing a share file.
const shareExportPixelRatio = 2.0;

const shareFontFallbacks = <String>[
  'Noto Naskh Arabic',
  'Noto Sans Arabic',
  'Geeza Pro',
  'Noto Sans Devanagari',
  'Kohinoor Devanagari',
  'PingFang SC',
  'Hiragino Sans',
  'Noto Sans CJK SC',
  'Noto Sans Thai',
  'Thonburi',
  'Noto Sans Hebrew',
  'Arial Hebrew',
];

enum ShareTemplate { dark, light, cover, minimal }

enum ShareFormat { story, portrait, square }

Size shareFormatSize(ShareFormat format) {
  return switch (format) {
    ShareFormat.story => const Size(shareStoryWidth, shareStoryHeight),
    ShareFormat.portrait => const Size(shareStoryWidth, sharePortraitHeight),
    ShareFormat.square => const Size(shareStoryWidth, shareSquareHeight),
  };
}

double shareSafeTop(ShareFormat format) {
  return format == ShareFormat.story ? shareStorySafeTop : shareOtherSafeTop;
}

double shareSafeBottom(ShareFormat format) {
  return format == ShareFormat.story
      ? shareStorySafeBottom
      : shareOtherSafeBottom;
}

double shareQuoteLineHeight(String language) {
  if (languageByCode(language)?.rtl == true) return 1.45;
  if (language == 'zh' || language == 'ja' || language == 'ko') return 1.35;
  if (language == 'hi') return 1.4;
  return 1.2;
}

double shareQuoteFontMax(ShareFormat format) {
  return switch (format) {
    ShareFormat.story => shareQuoteFontMaxStory,
    ShareFormat.portrait => shareQuoteFontMaxPortrait,
    ShareFormat.square => shareQuoteFontMaxSquare,
  };
}

String shareCacheKey({
  required String itemId,
  required ShareTemplate template,
  required ShareFormat format,
  required String language,
}) {
  return '$itemId/${template.name}/${format.name}/$language';
}

Rect shareSafeRect(Size size, ShareFormat format) {
  final top = size.height * shareSafeTop(format);
  final bottom = size.height * shareSafeBottom(format);
  return Rect.fromLTRB(0, top, size.width, size.height - bottom);
}

TextDirection mixedDirection(String text, TextDirection fallback) {
  if (text.trim().isEmpty) return fallback;
  return Bidi.detectRtlDirectionality(text)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

class QuoteFit {
  const QuoteFit({required this.fontSize, required this.tall});

  final double fontSize;
  final bool tall;
}

/// Largest font that paints the exact quote in [maxWidth] × [maxHeight].
/// Never truncates. If the minimum still overflows, [tall] is true so the
/// card can give the quote more of the vertical space.
QuoteFit fitQuoteFont({
  required String text,
  required TextDirection direction,
  required String language,
  required double maxWidth,
  required double maxHeight,
  required double minSize,
  required double maxSize,
}) {
  bool fits(double size, double height) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: _quoteStyle(size, language, const Color(0xFFFFFFFF)),
      ),
      textDirection: direction,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    return painter.height <= height && painter.didExceedMaxLines == false;
  }

  var lo = minSize;
  var hi = maxSize;
  var best = minSize;
  for (var i = 0; i < 14; i++) {
    final mid = (lo + hi) / 2;
    if (fits(mid, maxHeight)) {
      best = mid;
      lo = mid;
    } else {
      hi = mid;
    }
  }
  if (fits(best, maxHeight)) return QuoteFit(fontSize: best, tall: false);
  final tallHeight = maxHeight + 72;
  lo = minSize;
  hi = maxSize;
  best = minSize;
  for (var i = 0; i < 14; i++) {
    final mid = (lo + hi) / 2;
    if (fits(mid, tallHeight)) {
      best = mid;
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return QuoteFit(fontSize: best, tall: true);
}

TextStyle _quoteStyle(double size, String language, Color color) {
  return TextStyle(
    fontFamily: 'Playfair',
    fontFamilyFallback: shareFontFallbacks,
    fontSize: size,
    height: shareQuoteLineHeight(language),
    fontWeight: FontWeight.w600,
    color: color,
    decoration: TextDecoration.none,
  );
}

class QuoteCardWidget extends StatelessWidget {
  const QuoteCardWidget({
    super.key,
    required this.item,
    required this.template,
    required this.format,
    required this.language,
    this.translatedLabel = 'Translated',
    this.portraitUrl,
  });

  final Item item;
  final ShareTemplate template;
  final ShareFormat format;
  final String language;
  final String translatedLabel;
  final String? portraitUrl;

  @override
  Widget build(BuildContext context) {
    final size = shareFormatSize(format);
    final top = size.height * shareSafeTop(format);
    final bottom = size.height * shareSafeBottom(format);
    final pad = 64.0;
    final light = template == ShareTemplate.light;
    final quoteColor = light ? const Color(0xFF111111) : kCream;
    final metaColor = light ? const Color(0xFF5C574F) : const Color(0xCCF4F1EA);
    final accent = light ? const Color(0xFFC4622D) : const Color(0xFFE07A4A);
    final direction = languageByCode(language)?.direction ?? TextDirection.ltr;
    final innerWidth = size.width - pad * 2;
    final innerHeight = size.height - top - bottom;
    final reserved = template == ShareTemplate.minimal ? 360.0 : 420.0;
    final firstFit = fitQuoteFont(
      text: item.text,
      direction: direction,
      language: language,
      maxWidth: innerWidth,
      maxHeight: innerHeight - reserved,
      minSize: shareQuoteFontMin,
      maxSize: shareQuoteFontMax(format),
    );
    final tall = firstFit.tall;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1;
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: dpr,
        textScaler: TextScaler.noScaling,
        padding: EdgeInsets.zero,
      ),
      child: Directionality(
        textDirection: direction,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Background(item: item, template: template),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, top, pad, bottom),
                child: Column(
                  children: [
                    if (item.isTranslated)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          translatedLabel,
                          key: const Key('quote-card-translated'),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontFamilyFallback: shareFontFallbacks,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: accent,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    if (item.isTranslated) SizedBox(height: tall ? 8 : 16),
                    _TopMark(item: item, portraitUrl: portraitUrl),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.text,
                            key: const Key('quote-card-quote'),
                            textAlign: TextAlign.center,
                            style: _quoteStyle(
                              firstFit.fontSize,
                              language,
                              quoteColor,
                            ),
                          ),
                          SizedBox(height: tall ? 18 : 28),
                          Text(
                            '— ${item.author}',
                            key: const Key('quote-card-author'),
                            textAlign: TextAlign.center,
                            textDirection: mixedDirection(
                              item.author,
                              direction,
                            ),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontFamilyFallback: shareFontFallbacks,
                              fontSize: (firstFit.fontSize * 0.62).clamp(
                                32,
                                46,
                              ),
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                              color: quoteColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.source.line,
                            key: const Key('quote-card-source'),
                            textAlign: TextAlign.center,
                            textDirection: mixedDirection(
                              item.source.line,
                              direction,
                            ),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontFamilyFallback: shareFontFallbacks,
                              fontSize: 22,
                              height: 1.3,
                              color: metaColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tall ? 16 : 28),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: _Wordmark(light: light),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.item, required this.template});

  final Item item;
  final ShareTemplate template;

  @override
  Widget build(BuildContext context) {
    switch (template) {
      case ShareTemplate.minimal:
        return const ColoredBox(color: Color(0xFF0B0B0D));
      case ShareTemplate.light:
        return const ColoredBox(color: Color(0xFFF4F1EA));
      case ShareTemplate.dark:
        return Stack(
          fit: StackFit.expand,
          children: [
            GeneratedCover(field: item.field, seed: item.id, subtle: true),
            const ColoredBox(color: Color(0x990B0B0D)),
          ],
        );
      case ShareTemplate.cover:
        return Stack(
          fit: StackFit.expand,
          children: [
            GeneratedCover(field: item.field, seed: item.id),
            const ColoredBox(color: Color(0xB30B0B0D)),
          ],
        );
    }
  }
}

class _TopMark extends StatelessWidget {
  const _TopMark({required this.item, this.portraitUrl});

  final Item item;
  final String? portraitUrl;

  static const size = 132.0;

  @override
  Widget build(BuildContext context) {
    final own = item.imageUrl;
    final url = (own != null && own.isNotEmpty) ? own : portraitUrl;
    final radius = BorderRadius.circular(size * 0.22);
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        key: const Key('quote-card-portrait'),
        borderRadius: radius,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: imageHeaders,
          errorBuilder: (_, _, _) => const _AppIcon(size: size),
        ),
      );
    }
    return const _AppIcon(size: size);
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('quote-card-app-icon'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      alignment: Alignment.center,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(kCream, BlendMode.srcIn),
        child: Image.asset(
          'assets/images/mark.png',
          width: size * 0.62,
          height: size * 0.62,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.light});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? const Color(0xFF111111) : kCream;
    return Row(
      key: const Key('quote-card-wordmark'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Image.asset(
            'assets/images/mark.png',
            width: 20,
            height: 20,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          kAppName,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
