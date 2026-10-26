import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';
import 'study_page.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _page = PageController(viewportFraction: 0.92);
  var _index = 0;
  var _signature = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signature = AppScope.of(context).followed
        .map((field) => field.name)
        .join(',');
    if (signature != _signature) {
      final reset = _signature.isNotEmpty;
      _signature = signature;
      if (reset) {
        _index = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_page.hasClients) _page.jumpToPage(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.discoverItems.isNotEmpty
        ? state.discoverItems
        : discoverOrder(state.followed, state.items);
    final top = MediaQuery.paddingOf(context).top;
    return PageView.builder(
      controller: _page,
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      onPageChanged: (index) => setState(() => _index = index),
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(8, top + 12, 8, dockInset(context)),
          child: _DiscoverCard(item: item, active: index == _index),
        );
      },
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.item, required this.active});

  final Item item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final saved = state.saved.contains(item.id);
    final read = state.read.contains(item.id);
    return RiseIn(
      play: active,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: palette.backdrop.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: palette.cardAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  fieldInfo[item.field]!.title,
                  style: sans(
                    palette,
                    12,
                    weight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.author,
              textAlign: TextAlign.center,
              style: serif(palette, 32, height: 1.1),
            ),
            const SizedBox(height: 4),
            Text(
              item.source.line,
              textAlign: TextAlign.center,
              style: sans(palette, 13, color: palette.textFaint),
            ),
            const SizedBox(height: 16),
            Text(
              item.text,
              textAlign: TextAlign.center,
              style: serif(
                palette,
                18,
                height: 1.4,
                style: FontStyle.italic,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CONTEXT',
              style: sans(
                palette,
                12,
                weight: FontWeight.w700,
                color: palette.textFaint,
              ),
            ),
            const SizedBox(height: 8),
            Text(item.deeper.context, style: sans(palette, 16, height: 1.45)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.cardAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DID YOU KNOW?',
                        style: sans(
                          palette,
                          12,
                          weight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.deeper.didYouKnow,
                    style: sans(palette, 15, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final related
                    in item.deeper.related
                        .map((id) => itemById(id, state.items))
                        .whereType<Item>())
                  ChoiceChipButton(
                    label: related.author,
                    selected: false,
                    onTap: () => openStudy(context, related),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Pressable(
                onPressed: () => openStudy(context, item),
                semanticLabel: 'Go deeper',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Go deeper  ›',
                    style: sans(
                      palette,
                      15,
                      weight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            if (!item.verified) const Center(child: UnverifiedMark()),
            if (item.imageCredit != null)
              PhotoCreditLine(credit: item.imageCredit!),
            SourceLine(item: item),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => state.toggleSave(item.id),
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: palette.textMuted,
                  ),
                ),
                IconButton(
                  onPressed: () => openStudy(context, item),
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: palette.textMuted,
                  ),
                ),
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => shareItem(context, item),
                    icon: Icon(
                      Icons.ios_share_rounded,
                      color: palette.textMuted,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => state.toggleRead(item.id),
                  icon: Icon(
                    read ? Icons.check_circle : Icons.check_circle_outline,
                    color: read ? palette.accent : palette.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
