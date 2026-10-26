import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';

class SpeechScreen extends StatelessWidget {
  const SpeechScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return Scaffold(
      backgroundColor: palette.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GeneratedCover(field: item.field, seed: 'speech-${item.id}'),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0x00000000), palette.bg],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 16,
                  child: Pressable(
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: 'Close',
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: palette.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY · ${weekdays[now.weekday - 1].toUpperCase()}, ${now.day} ${months[now.month - 1].toUpperCase()}',
                  style: sans(
                    palette,
                    12,
                    weight: FontWeight.w600,
                    color: palette.textFaint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.source.title, style: serif(palette, 36, height: 1.1)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Meta(
                      icon: Icons.category_outlined,
                      label: fieldInfo[item.field]!.title,
                    ),
                    if (item.source.year != null)
                      _Meta(
                        icon: Icons.menu_book_outlined,
                        label: '${item.source.year}',
                      ),
                    _Meta(
                      icon: Icons.schedule_rounded,
                      label: item.durationLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.deeper.context,
                  style: sans(palette, 16, height: 1.45),
                ),
                const SizedBox(height: 8),
                SourceLine(item: item),
                if (item.imageCredit != null)
                  PhotoCreditLine(credit: item.imageCredit!),
                const SizedBox(height: 24),
                if ((item.speech?.watchUrl ?? '').isNotEmpty) ...[
                  OutlineButton(
                    label: 'Watch full speech',
                    onPressed: () => openLink(item.speech!.watchUrl),
                  ),
                  const SizedBox(height: 8),
                ],
                PrimaryButton(
                  label: 'Start reading',
                  onPressed: () {
                    Navigator.of(context).pop();
                    AppScope.of(context).openInFeed(item.id);
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'More speeches',
                  style: sans(palette, 20, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final other in AppScope.of(context).items.where(
                        (entry) => entry.isSpeech && entry.id != item.id,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Pressable(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => SpeechScreen(item: other),
                                ),
                              );
                            },
                            semanticLabel: other.source.title,
                            child: Container(
                              width: 180,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: palette.cardAlt,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    other.source.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: sans(
                                      palette,
                                      16,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    other.author,
                                    style: sans(
                                      palette,
                                      12,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                  Text(
                                    other.durationLabel,
                                    style: sans(
                                      palette,
                                      12,
                                      color: palette.textFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
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

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(label, style: sans(palette, 12, color: palette.textMuted)),
        ],
      ),
    );
  }
}
