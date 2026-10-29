import 'package:flutter/material.dart';

import '../l10n/ui_text.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import '../widgets/go_deeper.dart';
import '../widgets/quote_tap.dart';
import 'notes_sheet.dart';
import 'study_page.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _page = PageController(viewportFraction: 0.92);
  var _index = 0;
  var _deck = 0;
  var _signature = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final signature =
        '${state.browseAll}|${state.collectionFocus?.name ?? ''}|${state.followed.map((field) => field.name).join(',')}';
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
    if (_deck != 0 && state.discoverShuffle != _deck) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_page.hasClients) _page.jumpToPage(0);
      });
    }
    _deck = state.discoverShuffle;
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  List<Item> _visible(AppState state) {
    bool keep(Item item) => state.showsInFeed(item);
    final open =
        state.browseAll ||
        (state.collectionFocus == null && state.followed.isEmpty);
    if (open && state.items.isNotEmpty) {
      return freshDeck(state.items, state.discoverShuffle);
    }
    final merged = state.items.where(keep).toList();
    for (final item in state.discoverItems.where(keep)) {
      if (merged.every((other) => other.id != item.id)) merged.add(item);
    }
    if (merged.isEmpty) {
      final fallback = state.discoverItems.isNotEmpty
          ? state.discoverItems
          : state.items;
      return freshDeck(fallback, state.discoverShuffle);
    }
    return freshDeck(merged, state.discoverShuffle);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final items = _visible(state);
    final top = MediaQuery.paddingOf(context).top;
    if (items.isEmpty) {
      if (state.catalogOpening) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, top + 24, 24, dockInset(context)),
          child: const CatalogOpening(),
        );
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(24, top + 24, 24, dockInset(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.items.isEmpty
                  ? (state.catalogError ?? 'Nothing is published yet.')
                  : 'Nothing in this collection yet.',
              textAlign: TextAlign.center,
              style: sans(palette, 16, color: palette.textMuted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: state.items.isEmpty ? 'Try again' : 'See everything',
              onPressed: state.items.isEmpty
                  ? state.refreshCatalog
                  : state.showEverything,
            ),
          ],
        ),
      );
    }
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
    final portrait = state.portraitFor(item.author);
    final imageUrl = item.imageUrl ?? portrait?.imageUrl;
    final credit = item.imageCredit ?? portrait?.imageCredit;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openStudy(context, item),
      child: RiseIn(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Pressable(
                                  semanticLabel: fieldInfo[item.field]!.title,
                                  onPressed: () =>
                                      state.focusCollection(item.field),
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
                              ),
                              const SizedBox(height: 10),
                              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                AuthorAvatar(
                                  author: item.author,
                                  size: 64,
                                  imageUrl: imageUrl,
                                  imageCredit: credit,
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                item.author,
                                textAlign: TextAlign.center,
                                style: serif(palette, 36, height: 1.08),
                              ),
                              const SizedBox(height: 10),
                              QuoteTap(
                                itemId: item.id,
                                onOpen: () => openStudy(context, item),
                                child: Text(
                                  item.text,
                                  textAlign: TextAlign.center,
                                  style: serif(
                                    palette,
                                    26,
                                    height: 1.28,
                                    style: FontStyle.italic,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CONTEXT',
                                style: sans(
                                  palette,
                                  12,
                                  weight: FontWeight.w700,
                                  color: palette.textFaint,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.shownContext,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: sans(palette, 17, height: 1.35),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
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
                                      item.shownDidYouKnow,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: sans(palette, 17, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final related
                                      in item.deeper.related
                                          .map(
                                            (id) => itemById(id, state.items),
                                          )
                                          .whereType<Item>())
                                    ChoiceChipButton(
                                      label: related.author,
                                      selected: false,
                                      onTap: () => openStudy(context, related),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: Pressable(
                    onPressed: () => openStudy(context, item),
                    semanticLabel: 'Go deeper',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${ui(AppScope.of(context).uiLanguage ?? AppScope.of(context).resolvedContentLanguage(View.of(context).platformDispatcher.locale), 'goDeeper')}  ›',
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
                if (item.imageCredit != null)
                  PhotoCreditLine(credit: item.imageCredit!, maxLines: 1),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => state.toggleSave(item.id),
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: palette.textMuted,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Notes',
                      onPressed: () => showNotes(context, item),
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: palette.textMuted,
                      ),
                    ),
                    Builder(
                      builder: (context) => IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => shareItem(context, item),
                        icon: Icon(
                          Icons.ios_share_rounded,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
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
        ),
      ),
    );
  }
}
