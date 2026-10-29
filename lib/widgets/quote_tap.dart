import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

/// Single tap opens the line. Double tap likes it and shows a heart.
class QuoteTap extends StatefulWidget {
  const QuoteTap({
    super.key,
    required this.itemId,
    required this.child,
    this.onOpen,
  });

  final String itemId;
  final Widget child;
  final VoidCallback? onOpen;

  @override
  State<QuoteTap> createState() => _QuoteTapState();
}

class _QuoteTapState extends State<QuoteTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _like() {
    final state = AppScope.of(context);
    if (!state.liked.contains(widget.itemId)) {
      state.toggleLike(widget.itemId);
    }
    HapticFeedback.mediumImpact();
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOpen,
      onDoubleTap: _like,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                final t = _burst.value;
                if (t == 0 || _burst.isDismissed) {
                  return const SizedBox.shrink();
                }
                final fade = t < 0.65 ? 1.0 : (1 - t) / 0.35;
                final scale = reduce ? 1.0 : 0.55 + (t < 0.4 ? t / 0.4 : 1) * 0.6;
                return Opacity(
                  opacity: fade.clamp(0, 1),
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 88,
                      color: Color(0xFFE07A4A),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
