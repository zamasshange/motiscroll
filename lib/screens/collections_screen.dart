import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/generated_cover.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, dockInset(context)),
      children: [
        Text('Collections', style: serif(palette, 36)),
        const SizedBox(height: 8),
        Text(
          'Follow a field and it leads Discover.',
          style: sans(palette, 15, color: palette.textMuted),
        ),
        const SizedBox(height: 24),
        for (final field in collectionFields) ...[
          _FieldCard(
            field: field,
            count: countForField(field, state.items),
            following: state.followed.contains(field),
            onFollow: () => state.toggleFollow(field),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.count,
    required this.following,
    required this.onFollow,
  });

  final Field field;
  final int count;
  final bool following;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final info = fieldInfo[field]!;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GeneratedCover(field: field, seed: field.name),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          info.title,
                          style: serif(darkPalette, 32, color: kCream),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0B0B0D),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                        ),
                        child: Text(
                          count == 1 ? '1 line' : '$count lines',
                          style: sans(
                            darkPalette,
                            12,
                            weight: FontWeight.w600,
                            color: kCream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    info.description,
                    style: sans(palette, 14, color: palette.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                FollowButton(following: following, onPressed: onFollow),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
