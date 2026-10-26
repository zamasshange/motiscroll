import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final items = AppScope.of(context).items
        .where((item) => state.saved.contains(item.id))
        .toList();
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        elevation: 0,
        title: Text('Saved', style: serif(palette, 22)),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'Nothing saved yet.',
                style: sans(palette, 16, color: palette.textMuted),
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
                              const SizedBox(height: 8),
                              SourceLine(item: item),
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
