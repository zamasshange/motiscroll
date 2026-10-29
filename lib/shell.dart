import 'package:flutter/material.dart';

import 'l10n/ui_text.dart';
import 'screens/collections_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';
import 'theme/tokens.dart';

class TabShell extends StatefulWidget {
  const TabShell({super.key});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  var _index = 2;

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
    if (target != null && _index != 3) {
      setState(() => _index = 3);
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    final state = AppScope.of(context);
    if (index == 1) state.reshuffleDiscover();
    if (index == 3) state.reshuffleFeed();
    if (index == 1 || index == 3) state.noteVisit();
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
              CollectionsScreen(),
              DiscoverScreen(),
              HomeScreen(),
              FeedScreen(),
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
                      icon: Icons.grid_view_rounded,
                      label: ui(code, 'collections'),
                      selected: _index == 0,
                      onTap: () => _select(0),
                    ),
                    _Tab(
                      icon: Icons.auto_awesome,
                      label: ui(code, 'discover'),
                      selected: _index == 1,
                      onTap: () => _select(1),
                    ),
                    _Tab(
                      icon: Icons.home_rounded,
                      label: ui(code, 'home'),
                      selected: _index == 2,
                      onTap: () => _select(2),
                    ),
                    _Tab(
                      icon: Icons.menu_book_rounded,
                      label: ui(code, 'feed'),
                      selected: _index == 3,
                      onTap: () => _select(3),
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
