import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';

void showNotes(BuildContext context, Item item) {
  final state = AppScope.of(context);
  final palette = state.palette;
  final controller = TextEditingController(text: state.notes[item.id] ?? '');
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
    ),
    builder: (context) {
      final bottom = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  state.setNote(item.id, controller.text);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: palette.text,
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0x14000000)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'Done',
                  style: sans(palette, 15, weight: FontWeight.w600),
                ),
              ),
            ),
            Text(
              item.source.line,
              textAlign: TextAlign.center,
              style: sans(palette, 18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              item.text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: sans(palette, 14, color: palette.textMuted),
            ),
            const SizedBox(height: 12),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Your notes',
                  style: sans(palette, 13, color: palette.textMuted),
                ),
                const Spacer(),
                Text(
                  'Saved on this phone',
                  style: sans(palette, 13, color: palette.textFaint),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 5,
              maxLines: 8,
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
      );
    },
  ).whenComplete(controller.dispose);
}
