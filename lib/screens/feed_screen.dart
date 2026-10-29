import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';
import '../widgets/quote_tap.dart';
import 'line_screen.dart';
import 'notes_sheet.dart';
import 'study_page.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _page = PageController();
  var _index = 0;
  var _deck = 0;
  Field? _field;
  Mood? _mood;
  var _forceAll = false;
  String? _applied;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final mark = '${state.browseAll}|${state.collectionFocus?.name ?? ''}';
    if (_applied != null && mark != _applied) {
      _forceAll = false;
      _field = state.collectionFocus;
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_page.hasClients) _page.jumpToPage(0);
      });
    }
    _applied = mark;
    _field = state.browseAll ? null : state.collectionFocus;
    if (_deck != 0 && state.feedDeck != _deck) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_page.hasClients) _page.jumpToPage(0);
      });
    }
    _deck = state.feedDeck;
    final id = state.feedTarget;
    if (id == null) return;
    state.consumeFeedTarget();
    if (!state.items.any((item) => item.id == id)) return;
    _forceAll = true;
    _field = null;
    _mood = null;
    final index = _entries.indexWhere((entry) => entry.item.id == id);
    if (index < 0) return;
    setState(() => _index = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_page.hasClients) _page.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  List<_Entry> get _entries {
    final state = AppScope.of(context);
    final lines = state.items.where((item) {
      if (_mood != null && !item.moods.contains(_mood)) return false;
      return true;
    }).toList();
    if (_forceAll) return _mix(lines);
    final focusedLines = lines.where(state.showsInFeed).toList();
    if (focusedLines.isEmpty) return _mix(lines);
    return _mix(focusedLines);
  }

  List<_Entry> _mix(List<Item> lines) {
    return [
      for (final line in freshDeck(lines, AppScope.of(context).feedDeck))
        _Entry.line(line),
    ];
  }

  void _go(int index) {
    if (!mounted || index < 0 || index >= _entries.length) return;
    if (!_page.hasClients) {
      setState(() => _index = index);
      return;
    }
    final current = _page.page?.round() ?? _index;
    if ((current - index).abs() <= 1) {
      _page.animateToPage(
        index,
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    // A short animation across thousands of lines keeps the feed's
    // scroller busy, so taps and swipes do nothing until it finishes.
    _page.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final entries = _entries;
    final top = MediaQuery.paddingOf(context).top;
    final entry = entries.isEmpty
        ? null
        : entries[_index.clamp(0, entries.length - 1)];
    final item = entry?.item;
    return Column(
      children: [
        SizedBox(height: top + 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CircleButton(
                icon: Icons.grid_view_rounded,
                label: 'All lines',
                onTap: () => _showLines(entries),
              ),
              const SizedBox(width: 8),
              if (item != null)
                _CircleButton(
                  icon: state.liked.contains(item.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  color: state.liked.contains(item.id) ? palette.accent : null,
                  onTap: () => state.toggleLike(item.id),
                ),
              if (item != null) const SizedBox(width: 8),
              if (entry != null)
                Flexible(
                  child: _Pill(
                    label: fieldInfo[entry.field]!.title,
                    onTap: () => state.focusCollection(entry.field),
                    trailing: Icons.tune_rounded,
                    onTrailing: _showFilters,
                  ),
                ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item != null)
                      _CircleButton(
                        icon: state.saved.contains(item.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: 'Save',
                        onTap: () => state.toggleSave(item.id),
                      ),
                    if (item != null) const SizedBox(width: 8),
                    if (entry != null)
                      Flexible(
                        child: _Pill(
                          label: entry.name.split(' ').last,
                          trailing: Icons.expand_more_rounded,
                          onTap: () => _showPeople(entries, entry.name),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.items.isEmpty
                            ? (state.catalogError ??
                                  'Nothing is published yet.')
                            : 'Nothing in this filter.',
                        style: sans(palette, 16, color: palette.textMuted),
                      ),
                      const SizedBox(height: 16),
                      OutlineButton(
                        label: state.items.isEmpty
                            ? 'Try again'
                            : 'Clear filter',
                        onPressed: () {
                          if (state.items.isEmpty) {
                            state.refreshCatalog();
                            return;
                          }
                          state.showEverything();
                          setState(() {
                            _field = null;
                            _mood = null;
                            _forceAll = false;
                            _index = 0;
                          });
                        },
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _page,
                      scrollDirection: Axis.vertical,
                      itemCount: entries.length,
                      onPageChanged: (index) {
                        setState(() => _index = index);
                        if (index < 0 || index >= entries.length) return;
                        AppScope.of(context).noteLine(entries[index].item.id);
                        if (index >= entries.length - 5) {
                          AppScope.of(context).loadMore();
                        }
                      },
                      itemBuilder: (context, index) {
                        final line = entries[index].item;
                        final portrait = AppScope.of(
                          context,
                        ).portraitFor(line.author);
                        final credit = line.imageCredit ?? portrait?.imageCredit;
                        final imageUrl = line.imageUrl ?? portrait?.imageUrl;
                        final hasImage =
                            imageUrl != null && imageUrl.isNotEmpty;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            32,
                            8,
                            32,
                            dockInset(context) + 132,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Pressable(
                                    onPressed: () => openStudy(context, line),
                                    semanticLabel: 'Open the study',
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: palette.card,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: palette.backdrop.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: hasImage
                                          ? AuthorAvatar(
                                              author: line.author,
                                              size: 72,
                                              imageUrl: imageUrl,
                                              imageCredit: credit,
                                            )
                                          : SizedBox(
                                              width: 72,
                                              height: 72,
                                              child: Image.asset(
                                                'assets/images/mark.png',
                                                fit: BoxFit.contain,
                                                color: palette.text,
                                                colorBlendMode: BlendMode.srcIn,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Flexible(
                                    child: LayoutBuilder(
                                      builder: (context, inner) {
                                        return FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                QuoteTap(
                                                  itemId: line.id,
                                                  onOpen: () => openLineReader(
                                                    context,
                                                    line,
                                                  ),
                                                  child: Text(
                                                    line.text,
                                                    textAlign: TextAlign.center,
                                                    style: serif(
                                                      palette,
                                                      42,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  line.author,
                                                  textAlign: TextAlign.center,
                                                  style: sans(
                                                    palette,
                                                    18,
                                                    color: palette.textMuted,
                                                  ),
                                                ),
                                                if (credit != null) ...[
                                                  const SizedBox(height: 8),
                                                  PhotoCreditLine(
                                                    credit: credit,
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                    if (item != null)
                      Positioned(
                        right: 8,
                        bottom: dockInset(context) - 16,
                        child: _Rail(item: item),
                      ),
                    if (!state.hintDismissed)
                      Positioned(
                        left: 16,
                        bottom: dockInset(context) - 8,
                        child: _Hint(onClose: state.dismissHint),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showFilters() {
    final palette = AppScope.of(context).palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.paddingOf(sheetContext).bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter', style: serif(palette, 28)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final field in collectionFields)
                    ChoiceChipButton(
                      label: fieldInfo[field]!.title,
                      selected: _field == field,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        final next = _field == field ? null : field;
                        if (next == null) {
                          AppScope.of(context).focusCollection(null);
                        } else {
                          AppScope.of(context).focusCollection(next);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLines(List<_Entry> entries) {
    final palette = AppScope.of(context).palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.7,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              8,
              12,
              8,
              MediaQuery.paddingOf(sheetContext).bottom + 24,
            ),
            itemCount: entries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text('Lines', style: serif(palette, 28)),
                );
              }
              final entry = entries[index - 1];
              return ListTile(
                leading: Text(
                  '$index',
                  style: sans(palette, 14, color: palette.textMuted),
                ),
                title: Text(
                  entry.name,
                  style: sans(palette, 16, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  entry.item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(palette, 13, color: palette.textMuted),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _go(index - 1);
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showPeople(List<_Entry> entries, String current) {
    final palette = AppScope.of(context).palette;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final keyboard = media.viewInsets.bottom;
        final height = (media.size.height - keyboard) * 0.92;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SizedBox(
            height: height,
            child: _PersonPicker(
              entries: entries,
              current: current,
              onPick: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                final route = ModalRoute.of(sheetContext);
                Navigator.of(sheetContext).pop();
                route?.popped.whenComplete(() {
                  if (mounted) _go(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}

class _PersonPicker extends StatefulWidget {
  const _PersonPicker({
    required this.entries,
    required this.current,
    required this.onPick,
  });

  final List<_Entry> entries;
  final String current;
  final ValueChanged<int> onPick;

  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final first = <String, int>{};
    final counts = <String, int>{};
    final fields = <String, Field>{};
    for (var i = 0; i < widget.entries.length; i++) {
      final entry = widget.entries[i];
      first.putIfAbsent(entry.name, () => i);
      fields.putIfAbsent(entry.name, () => entry.field);
      counts[entry.name] = (counts[entry.name] ?? 0) + 1;
    }
    final query = _query.trim().toLowerCase();
    final names =
        first.keys
            .where(
              (name) => query.isEmpty || name.toLowerCase().contains(query),
            )
            .toList()
          ..sort();
    final groups = <Field, List<String>>{};
    for (final name in names) {
      groups.putIfAbsent(fields[name]!, () => []).add(name);
    }
    final rows = <_PickerRow>[];
    for (final field in Field.values) {
      final group = groups[field];
      if (group == null) continue;
      rows.add(_PickerRow.header(fieldInfo[field]!.title));
      for (final name in group) {
        rows.add(_PickerRow.person(name, first[name]!, counts[name] ?? 0));
      }
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(child: Text('Select person', style: serif(palette, 28))),
              IconButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.close_rounded, color: palette.text),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: sans(palette, 16),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: palette.textFaint),
                hintText: 'Search people',
              ),
            ),
          ),
        ),
        Expanded(
          child: names.isEmpty
              ? Center(
                  child: Text(
                    'No one matches that name.',
                    style: sans(palette, 15, color: palette.textMuted),
                  ),
                )
              : ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                      8,
                      12,
                      8,
                      MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row.header != null) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                          child: Text(
                            row.header!.toUpperCase(),
                            style: sans(
                              palette,
                              12,
                              weight: FontWeight.w600,
                              color: palette.textFaint,
                            ),
                          ),
                        );
                      }
                      final name = row.name!;
                      final selected = name == widget.current;
                      return ListTile(
                        title: Text(
                          name,
                          style: sans(
                            palette,
                            16,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected ? palette.accent : palette.text,
                          ),
                        ),
                        trailing: Text(
                          row.count == 1 ? '1 line' : '${row.count} lines',
                          style: sans(palette, 13, color: palette.textMuted),
                        ),
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          widget.onPick(row.index!);
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _PickerRow {
  const _PickerRow.header(this.header) : name = null, index = null, count = 0;
  const _PickerRow.person(this.name, this.index, this.count) : header = null;

  final String? header;
  final String? name;
  final int? index;
  final int count;
}

class _Entry {
  const _Entry.line(this.item);

  final Item item;

  Field get field => item.field;
  String get name => item.author;
}

class _Rail extends StatelessWidget {
  const _Rail({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final liked = state.liked.contains(item.id);
    final palette = state.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BareIcon(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: 'Like',
          color: liked ? palette.accent : palette.text,
          onTap: () => state.toggleLike(item.id),
        ),
        const SizedBox(height: 18),
        _BareIcon(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Notes',
          onTap: () => showNotes(context, item),
        ),
        const SizedBox(height: 18),
        Builder(
          builder: (context) => _BareIcon(
            icon: Icons.send_outlined,
            label: 'Share',
            onTap: () => shareItem(context, item),
          ),
        ),
      ],
    );
  }
}


class _BareIcon extends StatelessWidget {
  const _BareIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 26, color: color ?? palette.text),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: palette.backdrop.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_up_rounded, size: 16, color: palette.text),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Swipe up\n',
                  style: sans(
                    palette,
                    13,
                    height: 1.2,
                    weight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: 'for the next line',
                  style: sans(
                    palette,
                    13,
                    height: 1.2,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onPressed: onClose,
            semanticLabel: 'Dismiss hint',
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: palette.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.card,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: 18, color: color ?? palette.text),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onTap,
    this.trailing,
    this.onTrailing,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: sans(palette, 13, weight: FontWeight.w600),
                ),
              ),
            if (trailing != null && onTrailing != null) ...[
              const SizedBox(width: 4),
              Pressable(
                onPressed: onTrailing,
                semanticLabel: 'Filter',
                child: Icon(trailing, size: 16),
              ),
            ] else if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(trailing, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
