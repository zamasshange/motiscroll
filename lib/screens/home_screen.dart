import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';
import '../widgets/go_deeper.dart';
import '../widgets/quote_tap.dart';
import 'daily_screen.dart';
import 'line_screen.dart';
import 'habit_sheet.dart';
import 'notes_sheet.dart';
import 'paths_screen.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';
import 'speech_screen.dart';
import 'study_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FixedExtentScrollController? _fields;
  FixedExtentScrollController? _lines;
  var _fieldIndex = 0;
  var _indexed = false;
  var _lineIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_indexed) {
      final items = AppScope.of(context).items;
      final index = collectionFields.indexWhere(
        (field) => items.any((item) => item.field == field && item.verified),
      );
      if (index >= 0) _fieldIndex = index;
      _indexed = true;
    }
    _fields ??= FixedExtentScrollController(
      initialItem: _fieldIndex < 0 ? 0 : _fieldIndex,
    );
    _lines ??= FixedExtentScrollController();
  }

  @override
  void dispose() {
    _fields?.dispose();
    _lines?.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final top = MediaQuery.paddingOf(context).top;
    final localPicks = dailyPicks(DateTime.now(), state.usualMood, state.items);
    final picks = localPicks;
    final fields = collectionFields;
    final field = fields[_fieldIndex.clamp(0, fields.length - 1)];
    final lines = state.items.where((item) => item.field == field).toList();
    final line = lines.isEmpty
        ? picks?.quote
        : lines[_lineIndex.clamp(0, lines.length - 1)];
    if (picks == null || line == null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, top + 8, 16, dockInset(context)),
        children: [
          Text(
            _greeting(),
            style: sans(palette, 32, height: 1.1, weight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Text(
            state.catalogError ?? 'Nothing is published yet.',
            style: sans(palette, 16, color: palette.textMuted),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Try again', onPressed: state.refreshCatalog),
        ],
      );
    }
    return ListView(
      key: const Key('home-scroll'),
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, dockInset(context)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _greeting(),
                style: sans(palette, 32, height: 1.1, weight: FontWeight.w700),
              ),
            ),
            _IconTap(
              icon: Icons.local_fire_department_rounded,
              label: 'Streak',
              color: palette.accent,
              badge: '${state.streak}',
              onTap: () => showHabit(context),
            ),
            _IconTap(
              icon: Icons.bookmark_border_rounded,
              label: 'Saved',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LibraryScreen()),
              ),
            ),
            _IconTap(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Spacer(),
                  _TinyPill(fieldInfo[picks.quote.field]!.title),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  AuthorAvatar(
                    author: picks.quote.author,
                    size: 56,
                    imageUrl:
                        picks.quote.imageUrl ??
                        state.portraitFor(picks.quote.author)?.imageUrl,
                    imageCredit:
                        picks.quote.imageCredit ??
                        state.portraitFor(picks.quote.author)?.imageCredit,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          picks.quote.author,
                          style: sans(palette, 18, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QuoteTap(
                itemId: picks.quote.id,
                onOpen: () => openLineReader(context, picks.quote),
                child: Text(
                  picks.quote.text,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: serif(palette, 32, height: 1.25),
                ),
              ),
              const SizedBox(height: 8),
              if (picks.quote.imageCredit != null)
                PhotoCreditLine(credit: picks.quote.imageCredit!),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PlainIcon(
                    icon: state.liked.contains(picks.quote.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: 'Like',
                    onTap: () => state.toggleLike(picks.quote.id),
                  ),
                  _PlainIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Notes',
                    onTap: () => showNotes(context, picks.quote),
                  ),
                  Builder(
                    builder: (context) => _PlainIcon(
                      icon: Icons.send_outlined,
                      label: 'Share',
                      onTap: () => shareItem(context, picks.quote),
                    ),
                  ),
                  _PlainIcon(
                    icon: Icons.more_horiz_rounded,
                    label: 'Go deeper',
                    onTap: () => openStudy(context, picks.quote),
                  ),
                  _PlainIcon(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Daily',
                    onTap: () => openDaily(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: palette.text),
                  const SizedBox(width: 8),
                  Text(
                    'Line finder',
                    style: sans(palette, 18, weight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pick a field, then the line inside it.',
                      style: sans(palette, 13, color: palette.textMuted),
                    ),
                  ),
                  _PlainIcon(
                    icon: Icons.more_horiz_rounded,
                    label: 'Notes on this line',
                    onTap: () => showNotes(context, line),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _wheelExtent,
                child: Row(
                  children: [
                    Expanded(
                      child: _Wheel(
                        controller: _fields!,
                        count: fields.length,
                        selected: _fieldIndex,
                        label: (i) => fieldInfo[fields[i]]!.title,
                        onSelected: (i) => setState(() {
                          _fieldIndex = i;
                          _lineIndex = 0;
                          if (_lines != null && _lines!.hasClients) {
                            _lines!.jumpToItem(0);
                          }
                        }),
                      ),
                    ),
                    Expanded(
                      child: _Wheel(
                        controller: _lines!,
                        count: lines.length,
                        selected: _lineIndex.clamp(
                          0,
                          lines.isEmpty ? 0 : lines.length - 1,
                        ),
                        label: (i) => '${i + 1}',
                        circled: true,
                        onSelected: (i) => setState(() => _lineIndex = i),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Open this line',
                onPressed: () => state.openInFeed(line.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (picks.speech != null) ...[
          _Card(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: GeneratedCover(
                      field: picks.speech!.field,
                      seed: 'home-speech-${picks.speech!.id}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's speech",
                        style: sans(palette, 18, weight: FontWeight.w700),
                      ),
                      Text(
                        'Choose a path',
                        style: sans(palette, 15, weight: FontWeight.w600),
                      ),
                      Text(
                        picks.speech!.source.title,
                        style: sans(palette, 13, color: palette.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _PlainIcon(
                            icon: Icons.auto_awesome,
                            label: 'Paths',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PathsScreen(),
                              ),
                            ),
                          ),
                          _PlainIcon(
                            icon: Icons.lightbulb_outline,
                            label: 'Open speech',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    SpeechScreen(item: picks.speech!),
                              ),
                            ),
                          ),
                          _PlainIcon(
                            icon: Icons.menu_book_outlined,
                            label: 'Read',
                            onTap: () => state.openInFeed(picks.speech!.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "TODAY'S LINE",
                    style: sans(
                      palette,
                      11,
                      weight: FontWeight.w700,
                      color: palette.textFaint,
                    ),
                  ),
                  const Spacer(),
                  _TinyPill(
                    state.usualMood?.label ??
                        fieldInfo[picks.boost.field]!.title,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  AuthorAvatar(
                    author: picks.boost.author,
                    size: 64,
                    imageUrl:
                        picks.boost.imageUrl ??
                        state.portraitFor(picks.boost.author)?.imageUrl,
                    imageCredit:
                        picks.boost.imageCredit ??
                        state.portraitFor(picks.boost.author)?.imageCredit,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          picks.boost.author,
                          style: sans(palette, 18, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                picks.boost.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: sans(palette, 20, height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      picks.boost.durationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sans(palette, 13, color: palette.textMuted),
                    ),
                  ),
                  Pressable(
                    onPressed: () => openStudy(context, picks.boost),
                    semanticLabel: 'Start reading',
                    child: Text(
                      'Start reading  ›',
                      style: sans(palette, 14, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (picks.boost.imageCredit != null)
                PhotoCreditLine(credit: picks.boost.imageCredit!),
            ],
          ),
        ),
      ],
    );
  }
}

const _wheelExtent = 44.0;

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.count,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.circled = false,
  });

  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String Function(int index) label;
  final ValueChanged<int> onSelected;
  final bool circled;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    if (count == 0) return const SizedBox(height: _wheelExtent);
    return ClipRect(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _wheelExtent,
        diameterRatio: 1.1,
        perspective: 0.0001,
        overAndUnderCenterOpacity: 0,
        clipBehavior: Clip.hardEdge,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, index) {
            final on = index == selected;
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: on ? palette.cardAlt : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(circled ? 999 : 12),
                ),
                child: Text(
                  label(index),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(
                    palette,
                    18,
                    weight: FontWeight.w700,
                    color: on ? palette.text : palette.textFaint,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.backdrop.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: sans(
          palette,
          11,
          weight: FontWeight.w600,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 26, color: color ?? palette.text),
            if (badge != null) ...[
              const SizedBox(width: 2),
              Text(badge!, style: sans(palette, 16, weight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlainIcon extends StatelessWidget {
  const _PlainIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: palette.textMuted),
      ),
    );
  }
}
