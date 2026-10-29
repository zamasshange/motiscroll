import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../notifications/notification_text.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';

Item? onboardPreviewItem(AppState state) {
  final lines = onboardPreviewLines(state);
  if (lines.isEmpty) return null;
  return lines.first;
}

List<Item> onboardPreviewLines(AppState state) {
  final picks = dailyPicks(DateTime.now(), state.usualMood, state.items);
  if (picks == null) return state.items.take(2).toList();
  final second = picks.speech ?? picks.boost;
  if (second.id == picks.quote.id) return [picks.quote];
  return [picks.quote, second];
}

String? onboardPortrait(AppState state, Item item) {
  final own = item.imageUrl;
  if (own != null && own.isNotEmpty) return own;
  return state.portraitFor(item.author)?.imageUrl;
}

class OnboardDeviceFrame extends StatelessWidget {
  const OnboardDeviceFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        const logical = Size(390, 844);
        final scale = math.min(
          constraints.maxWidth / logical.width,
          constraints.maxHeight / logical.height,
        );
        if (scale <= 0) return const SizedBox.shrink();
        return Center(
          child: SizedBox(
            width: logical.width * scale,
            height: logical.height * scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(42 * scale),
                border: Border.all(color: palette.border, width: 1.5 * scale),
                boxShadow: [
                  BoxShadow(
                    color: palette.backdrop,
                    blurRadius: 28 * scale,
                    offset: Offset(0, 16 * scale),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10 * scale),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32 * scale),
                  child: FittedBox(
                    child: SizedBox(
                      width: logical.width,
                      height: logical.height,
                      child: IgnorePointer(child: child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardHomePreview extends StatelessWidget {
  const OnboardHomePreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final item = onboardPreviewItem(state);
    return ColoredBox(
      color: palette.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good afternoon',
              style: sans(palette, 28, height: 1.1, weight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LINE OF THE DAY',
                    style: sans(
                      palette,
                      11,
                      weight: FontWeight.w700,
                      color: palette.textFaint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (item != null) ...[
                    Text(
                      item.author,
                      style: sans(palette, 16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.text,
                      maxLines: compact ? 5 : 7,
                      overflow: TextOverflow.ellipsis,
                      style: serif(palette, 26, height: 1.22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.source.line,
                      style: sans(palette, 13, color: palette.textMuted),
                    ),
                  ] else ...[
                    Text(
                      'Short lines, still attached to the source.',
                      style: serif(palette, 26, height: 1.22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kAppName,
                      style: sans(palette, 13, color: palette.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 220,
                height: 58,
                decoration: BoxDecoration(
                  color: palette.tabBar,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.home_rounded, color: palette.accent, size: 22),
                    Icon(
                      Icons.auto_stories_outlined,
                      color: palette.textFaint,
                      size: 22,
                    ),
                    Icon(
                      Icons.explore_outlined,
                      color: palette.textFaint,
                      size: 22,
                    ),
                    Icon(
                      Icons.grid_view_rounded,
                      color: palette.textFaint,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardWidgetPreview extends StatelessWidget {
  const OnboardWidgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final item = onboardPreviewItem(state);
    return AspectRatio(
      aspectRatio: 0.78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: state.dark ? const Color(0xFF141418) : const Color(0xFFE8E6E1),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            children: [
              Text('9:41', style: sans(palette, 16, weight: FontWeight.w600)),
              const SizedBox(height: 18),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF0B0B0D)),
                      if (item != null)
                        GeneratedCover(
                          field: item.field,
                          seed: item.id,
                          subtle: true,
                        ),
                      const ColoredBox(color: Color(0xA10B0B0D)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OnboardSpeakerMark(
                              size: 40,
                              imageUrl: item == null
                                  ? null
                                  : onboardPortrait(state, item),
                            ),
                            const SizedBox(height: 10),
                            Flexible(
                              child: Text(
                                item?.text ?? 'Your daily quote appears here',
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: serif(
                                  palette,
                                  22,
                                  height: 1.25,
                                  color: kCream,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item?.author ?? kAppName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: sans(
                                palette,
                                18,
                                weight: FontWeight.w700,
                                color: const Color(0xFFE07A4A),
                              ),
                            ),
                            if (item != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.source.line,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sans(
                                  palette,
                                  13,
                                  color: const Color(0x99F4F1EA),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardNotificationPreview extends StatelessWidget {
  const OnboardNotificationPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lang = state.uiLanguage ?? state.contentLanguage ?? 'en';
    final lines = onboardPreviewLines(state);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Notice(
          title: morningTitle(lang, 0),
          item: lines.isEmpty ? null : lines.first,
        ),
        if (lines.length > 1) ...[
          const SizedBox(height: 10),
          _Notice(title: eveningTitle(lang, 0), item: lines[1]),
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.item});

  final String title;
  final Item? item;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final quote = item?.text ?? 'Your daily quote appears here';
    final author = item?.author ?? kAppName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardSpeakerMark(
            size: 40,
            imageUrl: item == null ? null : onboardPortrait(state, item!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(palette, 15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  quote,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: serif(palette, 16, height: 1.25),
                ),
                const SizedBox(height: 6),
                Text(
                  '— $author',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(
                    palette,
                    15,
                    weight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardSpeakerMark extends StatelessWidget {
  const OnboardSpeakerMark({super.key, required this.size, this.imageUrl});

  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: imageHeaders,
          errorBuilder: (_, _, _) => _AppMark(size: size),
        ),
      );
    }
    return _AppMark(size: size);
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: MotiMark(size: size * 0.62, color: kCream),
    );
  }
}
