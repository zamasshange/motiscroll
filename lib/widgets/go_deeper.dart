import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../screens/study_page.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'chrome.dart';

Future<void> shareItem(BuildContext context, Item item) async {
  final box = context.findRenderObject();
  Rect? origin;
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  final verified = item.verified ? '' : '\nNot verified';
  final text =
      '"${item.text}"\n— ${item.author}\nSource · ${item.source.line}$verified\n$kAppName';
  await SharePlus.instance.share(
    ShareParams(text: text, sharePositionOrigin: origin),
  );
}

class ItemActions extends StatelessWidget {
  const ItemActions({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final liked = state.liked.contains(item.id);
    final saved = state.saved.contains(item.id);
    return Row(
      children: [
        SpringIconButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          active: liked,
          label: liked ? 'Unlike' : 'Like',
          onPressed: () => state.toggleLike(item.id),
        ),
        SpringIconButton(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          active: saved,
          label: saved ? 'Unsave' : 'Save',
          onPressed: () => state.toggleSave(item.id),
        ),
        Builder(
          builder: (context) => SpringIconButton(
            icon: Icons.ios_share_rounded,
            active: false,
            label: 'Share',
            onPressed: () => shareItem(context, item),
          ),
        ),
        const Spacer(),
        Pressable(
          onPressed: () => openStudy(context, item),
          semanticLabel: 'Go deeper',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Go deeper',
              style: sans(
                palette,
                14,
                weight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void showGoDeeper(BuildContext context, Item item) {
  openStudy(context, item);
}
