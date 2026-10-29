import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';
import '../widgets/quote_tap.dart';
import 'notes_sheet.dart';
import 'study_page.dart';

/// Full-screen reading of one line. Text size stays for the rest of the session.
var _readerStep = 1;

void openLineReader(BuildContext context, Item item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LineScreen(item: item)),
  );
}

class LineScreen extends StatefulWidget {
  const LineScreen({super.key, required this.item});

  final Item item;

  @override
  State<LineScreen> createState() => _LineScreenState();
}

class _LineScreenState extends State<LineScreen> {
  var _menu = false;

  Item get item => widget.item;

  void _setSize(int step) {
    setState(() {
      _readerStep = step;
      _menu = false;
    });
  }

  void _moreFrom() {
    setState(() => _menu = false);
    final state = AppScope.of(context);
    final others = state.items
        .where((line) => line.author == item.author && line.id != item.id)
        .take(12)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: others.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'This is the only line we have from ${item.author}.',
                    style: sans(darkPalette, 16, color: darkPalette.text),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'More from ${item.author}',
                        style: sans(
                          darkPalette,
                          13,
                          weight: FontWeight.w700,
                          color: darkPalette.textMuted,
                        ),
                      ),
                    ),
                    for (final line in others)
                      ListTile(
                        title: Text(
                          line.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: serif(darkPalette, 18, height: 1.3),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          openLineReader(context, line);
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }

  void _customize() {
    setState(() => _menu = false);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text size', style: sans(darkPalette, 16, weight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final step in [0, 1, 2])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      const ['Small', 'Medium', 'Large'][step],
                      style: serif(
                        darkPalette,
                        const [22.0, 28.0, 34.0][step],
                      ),
                    ),
                    trailing: _readerStep == step
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _setSize(step);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final liked = state.liked.contains(item.id);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final base = item.text.length > 220
        ? 26.0
        : item.text.length > 120
        ? 32.0
        : 36.0;
    final size = base + (_readerStep - 1) * 6;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(28, top + 72, 28, bottom + 88),
            child: QuoteTap(
              itemId: item.id,
              onOpen: () => setState(() => _menu = false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  Text(
                    item.text,
                    style: serif(
                      darkPalette,
                      size,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.author,
                          style: sans(
                            darkPalette,
                            16,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Pressable(
                          onPressed: item.source.url == null
                              ? null
                              : () => openLink(item.source.url!),
                          semanticLabel: 'Source',
                          child: Text(
                            item.source.line,
                            style: sans(
                              darkPalette,
                              14,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 16,
            child: _RoundButton(
              icon: Icons.close_rounded,
              label: 'Close',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: top + 8,
            right: 16,
            child: _RoundButton(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: () => setState(() => _menu = !_menu),
            ),
          ),
          if (_menu)
            Positioned(
              top: top + 60,
              right: 16,
              child: _ReaderMenu(
                onCustomize: _customize,
                onStudy: () {
                  setState(() => _menu = false);
                  openStudy(context, item);
                },
                onMore: _moreFrom,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom + 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bare(
                  icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: liked ? 'Unlike' : 'Like',
                  color: liked ? darkPalette.accent : Colors.white,
                  onTap: () => state.toggleLike(item.id),
                ),
                const SizedBox(width: 36),
                _Bare(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Notes',
                  onTap: () => showNotes(context, item),
                ),
                const SizedBox(width: 36),
                Builder(
                  builder: (context) => _Bare(
                    icon: Icons.send_outlined,
                    label: 'Share',
                    onTap: () => shareItem(context, item),
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2E),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ReaderMenu extends StatelessWidget {
  const _ReaderMenu({
    required this.onCustomize,
    required this.onStudy,
    required this.onMore,
  });

  final VoidCallback onCustomize;
  final VoidCallback onStudy;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 230),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row(
              icon: Icons.tune_rounded,
              label: 'Customize',
              onTap: onCustomize,
            ),
            _Row(
              icon: Icons.menu_book_outlined,
              label: 'Open the study',
              onTap: onStudy,
            ),
            _Row(
              icon: Icons.library_books_outlined,
              label: 'More from this person',
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: sans(darkPalette, 16, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _Bare extends StatelessWidget {
  const _Bare({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
