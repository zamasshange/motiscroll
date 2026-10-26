import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/generated_cover.dart';

class PathsScreen extends StatelessWidget {
  const PathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      'Done',
                      style: sans(palette, 15, weight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Paths',
              textAlign: TextAlign.center,
              style: serif(palette, 28),
            ),
            const SizedBox(height: 8),
            Text(
              'A short run of lines for the mood you arrived with.',
              textAlign: TextAlign.center,
              style: sans(palette, 14, color: palette.textMuted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: palette.backdrop.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 84,
                      height: 84,
                      child: GeneratedCover(
                        field: Field.resilience,
                        seed: 'paths-start',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick a path to begin',
                          style: sans(palette, 16, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Each path is a short run of lines for one mood. Open one and it starts in Feed.',
                          style: sans(palette, 13, color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'BY MOOD',
              style: sans(
                palette,
                12,
                weight: FontWeight.w700,
                color: palette.textFaint,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
              children: [for (final mood in Mood.values) _PathCard(mood: mood)],
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.mood});

  final Mood mood;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final items = AppScope.of(context).items
        .where((item) => item.verified && item.moods.contains(mood))
        .toList();
    final minutes = items.fold<int>(0, (sum, item) {
      final seconds = item.speech?.durationSec ?? 45;
      return sum + seconds;
    });
    final mins = (minutes / 60).ceil().clamp(1, 999);
    final coverField = items.isEmpty ? Field.other : items.first.field;
    return GestureDetector(
      onTap: items.isEmpty
          ? null
          : () {
              Navigator.of(context).pop();
              AppScope.of(context).openInFeed(items.first.id);
            },
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GeneratedCover(field: coverField, seed: mood.name),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood.label,
                    style: sans(palette, 16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} lines · about $mins min',
                    style: sans(palette, 12, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
