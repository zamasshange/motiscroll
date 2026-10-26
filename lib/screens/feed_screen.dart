import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';
import 'study_page.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _page = PageController();
  var _index = 0;
  var _drag = 0.0;
  Field? _field;
  Mood? _mood;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = AppScope.of(context).feedTarget;
    if (id == null) return;
    AppScope.of(context).consumeFeedTarget();
    final index = AppScope.of(context).items
        .indexWhere((item) => item.id == id);
    if (index < 0) return;
    setState(() {
      _field = null;
      _mood = null;
      _index = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_page.hasClients) _page.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  List<Item> get _items {
    return AppScope.of(context).items.where((item) {
      if (_field != null && item.field != _field) return false;
      if (_mood != null && !item.moods.contains(_mood)) return false;
      return true;
    }).toList();
  }

  void _go(int index) {
    if (index < 0 || index >= _items.length) return;
    final reduce = reduceMotion(context);
    _page.animateToPage(
      index,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final items = _items;
    final top = MediaQuery.paddingOf(context).top;
    final item = items.isEmpty
        ? null
        : items[_index.clamp(0, items.length - 1)];
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
                onTap: () => _showLines(items),
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
              const SizedBox(width: 8),
              if (item != null)
                _Pill(label: fieldInfo[item.field]!.title, onTap: _showFilters),
              const Spacer(),
              if (item != null)
                _CircleButton(
                  icon: state.saved.contains(item.id)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: 'Save',
                  onTap: () => state.toggleSave(item.id),
                ),
              const SizedBox(width: 8),
              if (item != null)
                _Pill(
                  label: item.author.split(' ').last,
                  trailing: Icons.expand_more_rounded,
                  onTap: () => _showLines(items),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nothing in this filter.',
                        style: sans(palette, 16, color: palette.textMuted),
                      ),
                      const SizedBox(height: 16),
                      OutlineButton(
                        label: 'Clear filter',
                        onPressed: () => setState(() {
                          _field = null;
                          _mood = null;
                          _index = 0;
                        }),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _page,
                      scrollDirection: Axis.vertical,
                      itemCount: items.length,
                      onPageChanged: (index) {
                        setState(() => _index = index);
                        final state = AppScope.of(context);
                        final lines = state.items;
                        if (index >= 0 && index < lines.length) {
                          state.noteLine(lines[index].id);
                        }
                        if (index >= lines.length - 5) state.loadMore();
                      },
                      itemBuilder: (context, index) {
                        final line = items[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            56,
                            8,
                            72,
                            dockInset(context),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Pressable(
                                        onPressed: () =>
                                            openStudy(context, line),
                                        semanticLabel: 'Go deeper',
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: palette.card,
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: palette.backdrop
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: AuthorAvatar(
                                                author: line.author,
                                                size: 72,
                                                imageUrl: line.imageUrl,
                                                imageCredit: line.imageCredit,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Go deeper',
                                              style: sans(
                                                palette,
                                                12,
                                                color: palette.textFaint,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 36),
                                      Text(
                                        line.text,
                                        textAlign: TextAlign.center,
                                        style: serif(palette, 28, height: 1.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        line.source.line,
                                        textAlign: TextAlign.center,
                                        style: sans(
                                          palette,
                                          16,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      if (!line.verified) ...[
                                        const SizedBox(height: 8),
                                        const UnverifiedMark(),
                                      ],
                                      if (line.imageCredit != null) ...[
                                        const SizedBox(height: 8),
                                        PhotoCreditLine(
                                          credit: line.imageCredit!,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 4,
                      top: 24,
                      bottom: dockInset(context),
                      child: _Scrubber(
                        count: items.length,
                        index: _index,
                        onSelect: _go,
                        onDrag: (delta) {
                          _drag += delta;
                          if (_drag.abs() < 22) return;
                          final next = _index + (_drag > 0 ? 1 : -1);
                          _drag = 0;
                          HapticFeedback.selectionClick();
                          _go(next);
                        },
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: dockInset(context),
                      child: _Rail(item: item!),
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
                        setState(() {
                          _field = _field == field ? null : field;
                          _index = 0;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_page.hasClients) _page.jumpToPage(0);
                        });
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

  void _showLines(List<Item> items) {
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              8,
              12,
              8,
              MediaQuery.paddingOf(sheetContext).bottom + 24,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Lines', style: serif(palette, 28)),
              ),
              for (var i = 0; i < items.length; i++)
                ListTile(
                  leading: Text(
                    '${i + 1}',
                    style: sans(palette, 14, color: palette.textMuted),
                  ),
                  title: Text(
                    items[i].author,
                    style: sans(palette, 16, weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    items[i].source.line,
                    style: sans(palette, 13, color: palette.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _go(i);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
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
      mainAxisAlignment: MainAxisAlignment.center,
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
          label: 'Go deeper',
          onTap: () => openStudy(context, item),
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

class _Scrubber extends StatelessWidget {
  const _Scrubber({
    required this.count,
    required this.index,
    required this.onSelect,
    required this.onDrag,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelect;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final span = (height - 28).clamp(0.0, height).toDouble();
        final t = count <= 1 ? 0.0 : index / (count - 1);
        final y = t * span;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (count == 0 || height <= 0) return;
            final next = ((details.localPosition.dy / height) * count)
                .floor()
                .clamp(0, count - 1);
            onSelect(next);
          },
          onVerticalDragUpdate: (details) => onDrag(details.delta.dy),
          child: SizedBox(
            width: 52,
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    width: 1,
                    color: palette.textFaint.withValues(alpha: 0.7),
                  ),
                ),
                Positioned(
                  left: 7,
                  top: y,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: palette.text,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${index + 1}',
                        style: sans(palette, 13, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (count > 1)
                  Positioned(
                    left: 18,
                    bottom: 0,
                    child: Text(
                      '$count',
                      style: sans(palette, 11, color: palette.textFaint),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
          Icon(Icons.north_west_rounded, size: 16, color: palette.text),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Tap or slide\n',
                  style: sans(
                    palette,
                    13,
                    height: 1.2,
                    weight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: 'to jump to any line',
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
  const _Pill({required this.label, required this.onTap, this.trailing});

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

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
            Text(label, style: sans(palette, 13, weight: FontWeight.w600)),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(trailing, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
