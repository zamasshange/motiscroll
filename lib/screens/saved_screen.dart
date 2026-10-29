import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    List<Item> pick(Set<String> ids) =>
        state.items.where((item) => ids.contains(item.id)).toList();
    final shelves = [
      (
        Icons.bookmark_rounded,
        'Saved',
        pick(state.saved),
        'Nothing saved yet.',
      ),
      (
        Icons.favorite_rounded,
        'Liked',
        pick(state.liked),
        'Nothing liked yet.',
      ),
      (
        Icons.check_circle_rounded,
        'Read',
        pick(state.read),
        'Lines you mark as read appear here.',
      ),
      (
        Icons.edit_note_rounded,
        'Notes',
        pick(state.notes.keys.toSet()),
        'Notes you write on a line appear here.',
      ),
    ];
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Text('Your library', style: serif(palette, 36, height: 1.05)),
          const SizedBox(height: 24),
          for (final (icon, title, items, empty) in shelves)
            Pressable(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      _ShelfScreen(title: title, items: items, empty: empty),
                ),
              ),
              semanticLabel: '$title, ${items.length}',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: palette.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(icon, size: 20, color: palette.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(title, style: sans(palette, 17))),
                    Text(
                      '${items.length}',
                      style: sans(palette, 15, color: palette.textMuted),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: palette.textFaint),
                  ],
                ),
              ),
            ),
          if (state.followed.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Following',
              style: sans(palette, 13, color: palette.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in state.followed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(field.label, style: sans(palette, 14)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ShelfScreen extends StatelessWidget {
  const _ShelfScreen({
    required this.title,
    required this.items,
    required this.empty,
  });

  final String title;
  final List<Item> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        elevation: 0,
        title: Text(title, style: serif(palette, 22)),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  empty,
                  textAlign: TextAlign.center,
                  style: sans(palette, 16, color: palette.textMuted),
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final note = state.notes[item.id];
                return Pressable(
                  onPressed: () => showGoDeeper(context, item),
                  semanticLabel: item.author,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(kCardRadius),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthorAvatar(
                          author: item.author,
                          size: 56,
                          imageUrl: item.imageUrl,
                          imageCredit: item.imageCredit,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.author,
                                style: sans(
                                  palette,
                                  14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: serif(palette, 16, height: 1.3),
                              ),
                              if (note != null && note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  note,
                                  style: sans(
                                    palette,
                                    14,
                                    color: palette.accent,
                                  ),
                                ),
                              ],
                              if (item.imageCredit != null)
                                PhotoCreditLine(credit: item.imageCredit!),
                              if (!item.verified) const UnverifiedMark(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
