import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';

void showNotes(BuildContext context, Item item) {
  final palette = AppScope.of(context).palette;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.sheet,
    barrierColor: palette.backdrop,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
    ),
    builder: (context) => _NotesSheet(
      item: item,
      initial: AppScope.of(context).notes[item.id] ?? '',
    ),
  );
}

class _NotesSheet extends StatefulWidget {
  const _NotesSheet({required this.item, required this.initial});

  final Item item;
  final String initial;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final TextEditingController _controller;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    if (_closing) return;
    _closing = true;
    final text = _controller.text;
    final state = AppScope.of(context);
    Navigator.of(context).pop();
    state.setNote(widget.item.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: palette.sheet,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.cardAlt,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Pressable(
                onPressed: _done,
                semanticLabel: 'Done',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.cardAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Done',
                    style: sans(palette, 15, weight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Text(
                widget.item.author,
                textAlign: TextAlign.center,
                style: sans(palette, 18, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                widget.item.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: sans(palette, 14, color: palette.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: palette.cardAlt, height: 1, thickness: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your notes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: sans(palette, 13, color: palette.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Saved on this phone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: sans(palette, 13, color: palette.textFaint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 5,
              maxLines: 8,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _done(),
              style: sans(palette, 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: palette.cardAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
