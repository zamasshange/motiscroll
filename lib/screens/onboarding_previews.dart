import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';

Item? onboardPreviewItem(AppState state) {
  final picks = dailyPicks(DateTime.now(), state.usualMood, state.items);
  if (picks != null) return picks.quote;
  if (state.items.isEmpty) return null;
  return state.items.first;
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

class OnboardStudyPreview extends StatelessWidget {
  const OnboardStudyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final item = onboardPreviewItem(state);
    return ColoredBox(
      color: palette.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 54, 24, 32),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.close_rounded, color: palette.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              item?.author ?? kAppName,
              textAlign: TextAlign.center,
              style: serif(palette, 32, height: 1.1),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.cardAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item?.text ??
                    'Context, a fact, and a next step sit behind the line.',
                textAlign: TextAlign.center,
                style: serif(
                  palette,
                  18,
                  height: 1.4,
                  style: FontStyle.italic,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _StudyBlock(
              title: 'Context',
              body: item == null
                  ? 'The source stays in view with the line.'
                  : item.shownContext,
            ),
            const SizedBox(height: 12),
            _StudyBlock(
              title: 'Did you know',
              body: item == null
                  ? 'A short note on the person or the work.'
                  : item.shownDidYouKnow,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyBlock extends StatelessWidget {
  const _StudyBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: sans(palette, 13, weight: FontWeight.w700, color: palette.accent),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: sans(palette, 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class OnboardFeedPreview extends StatelessWidget {
  const OnboardFeedPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final item = onboardPreviewItem(state);
    return ColoredBox(
      color: palette.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item != null)
            GeneratedCover(field: item.field, seed: item.id, subtle: true),
          const ColoredBox(color: Color(0x990B0B0D)),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 48),
            child: Column(
              children: [
                const MotiMark(size: 36, color: kCream),
                const Spacer(),
                Text(
                  item?.text ?? 'One passage at a time.',
                  textAlign: TextAlign.center,
                  style: serif(
                    palette,
                    32,
                    height: 1.2,
                    color: kCream,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  item == null ? kAppName : '— ${item.author}',
                  textAlign: TextAlign.center,
                  style: sans(palette, 16, color: const Color(0xCCF4F1EA)),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
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
              Text(
                '9:41',
                style: sans(palette, 16, weight: FontWeight.w600),
              ),
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
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item?.text ?? 'Your daily quote appears here',
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: serif(
                                palette,
                                22,
                                height: 1.25,
                                color: kCream,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item?.author ?? kAppName,
                              style: sans(
                                palette,
                                14,
                                weight: FontWeight.w600,
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
                                  12,
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
