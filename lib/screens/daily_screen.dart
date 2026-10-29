import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';
import 'line_screen.dart';

void openDaily(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const DailyScreen()));
}

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late Timer _tick;
  var _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final local = dailyPicks(_now, state.usualMood, state.items);
    final today = local?.quote;
    final yesterday = dailyPicks(
      _now.subtract(const Duration(days: 1)),
      state.usualMood,
      state.items,
    )?.quote;
    final midnight = DateTime(_now.year, _now.month, _now.day + 1);
    final left = midnight.difference(_now);
    final countdown = [
      left.inHours,
      left.inMinutes % 60,
      left.inSeconds % 60,
    ].map((part) => part.toString().padLeft(2, '0')).join(':');

    final words = today == null
        ? 0
        : today.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (words / 180).ceil().clamp(1, 99);
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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
    final dateLine =
        'Today · ${weekdays[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]}';

    return Scaffold(
      backgroundColor: palette.bg,
      body: today == null
          ? Center(
              child: Text(
                state.catalogError ?? 'Nothing is published yet.',
                style: sans(palette, 16, color: palette.textMuted),
              ),
            )
          : ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Cover(item: today),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              kInk.withValues(alpha: 0.25),
                              kInk.withValues(alpha: 0),
                              kInk.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 8,
                        left: 16,
                        child: _Close(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLine.toUpperCase(),
                        style: sans(
                          palette,
                          12,
                          weight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        today.author,
                        style: serif(palette, 36, height: 1.05),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _Meta(
                            icon: Icons.sell_outlined,
                            label: fieldInfo[today.field]!.title,
                          ),
                          _Meta(
                            icon: Icons.schedule_rounded,
                            label: '$minutes min',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        today.shownContext,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: sans(palette, 16, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      Pressable(
                        semanticLabel: "Start today's line",
                        onPressed: () {
                          state.noteVisit();
                          openLineReader(context, today);
                        },
                        child: Container(
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.text,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: palette.bg,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Start today's line",
                                style: sans(
                                  palette,
                                  16,
                                  weight: FontWeight.w700,
                                  color: palette.bg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'More lines',
                        style: sans(palette, 22, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (yesterday != null)
                            Expanded(
                              child: _DayCard(
                                label: 'Yesterday',
                                title: yesterday.author,
                                subtitle: yesterday.text,
                                field: yesterday.field,
                                seed: 'daily-${yesterday.id}',
                                imageUrl: yesterday.imageUrl,
                                done: state.read.contains(yesterday.id),
                                onTap: () => openLineReader(context, yesterday),
                              ),
                            ),
                          if (yesterday != null) const SizedBox(width: 10),
                          Expanded(
                            child: _DayCard(
                              label: 'Tomorrow',
                              title: 'Unlocks in $countdown',
                              subtitle: 'A new line at midnight.',
                              field: today.field,
                              seed: 'daily-tomorrow',
                              locked: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    if (url == null || url.isEmpty) {
      return GeneratedCover(field: item.field, seed: 'daily-${item.id}');
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      headers: imageHeaders,
      errorBuilder: (context, error, stack) =>
          GeneratedCover(field: item.field, seed: 'daily-${item.id}'),
    );
  }
}

class _Close extends StatelessWidget {
  const _Close({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kInk.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: palette.textMuted),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sans(palette, 13, color: palette.textMuted),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.field,
    required this.seed,
    this.imageUrl,
    this.done = false,
    this.locked = false,
    this.onTap,
  });

  final String label;
  final String title;
  final String subtitle;
  final Field field;
  final String seed;
  final String? imageUrl;
  final bool done;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: locked ? null : onTap,
      semanticLabel: '$label, $title',
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      headers: imageHeaders,
                      errorBuilder: (context, error, stack) =>
                          GeneratedCover(field: field, seed: seed, subtle: locked),
                    )
                  else
                    GeneratedCover(field: field, seed: seed, subtle: locked),
                  if (locked)
                    ColoredBox(
                      color: kInk.withValues(alpha: 0.45),
                      child: const Icon(Icons.lock_rounded, color: Colors.white),
                    ),
                  if (done)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.check_circle_rounded, color: Colors.white),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: sans(
                      palette,
                      11,
                      weight: FontWeight.w700,
                      color: palette.textFaint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sans(palette, 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
