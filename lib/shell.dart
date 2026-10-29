import 'package:flutter/material.dart';

import 'l10n/ui_text.dart';
import 'screens/collections_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'state/app_state.dart';
import 'tabs.dart';
import 'theme/tokens.dart';

class TabShell extends StatefulWidget {
  const TabShell({super.key});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  var _index = AppTab.home;
  var _askShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    final tab = state.pendingTab;
    if (tab != null) {
      state.consumePendingTab();
      if (_index != tab) setState(() => _index = tab);
    }
    final target = state.feedTarget;
    if (target != null && _index != AppTab.feed) {
      setState(() => _index = AppTab.feed);
    }
    if (state.notificationAskPending && !_askShown) {
      _askShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationAskSheet(),
            fullscreenDialog: true,
          ),
        );
        if (mounted) _askShown = false;
      });
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    final state = AppScope.of(context);
    if (index == AppTab.discover) state.reshuffleDiscover();
    if (index == AppTab.feed) state.reshuffleFeed();
    if (index == AppTab.discover || index == AppTab.feed) state.noteVisit();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final code = state.uiLanguage ??
        state.resolvedContentLanguage(
          View.of(context).platformDispatcher.locale,
        );
    return Scaffold(
      backgroundColor: palette.bg,
      // The keyboard belongs to the sheet that opened it. Resizing this
      // shell crushes the feed and the layout error eats every tap.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              FeedScreen(),
              DiscoverScreen(),
              CollectionsScreen(),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.tabBar,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: palette.backdrop.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _Tab(
                      icon: Icons.home_rounded,
                      label: ui(code, 'home'),
                      selected: _index == AppTab.home,
                      onTap: () => _select(AppTab.home),
                    ),
                    _Tab(
                      icon: Icons.menu_book_rounded,
                      label: ui(code, 'feed'),
                      selected: _index == AppTab.feed,
                      onTap: () => _select(AppTab.feed),
                    ),
                    _Tab(
                      icon: Icons.auto_awesome,
                      label: ui(code, 'discover'),
                      selected: _index == AppTab.discover,
                      onTap: () => _select(AppTab.discover),
                    ),
                    _Tab(
                      icon: Icons.grid_view_rounded,
                      label: ui(code, 'collections'),
                      selected: _index == AppTab.collections,
                      onTap: () => _select(AppTab.collections),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final color = selected ? palette.text : palette.textFaint;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? palette.cardAlt : const Color(0x00000000),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(
                    palette,
                    10,
                    height: 1.1,
                    weight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
