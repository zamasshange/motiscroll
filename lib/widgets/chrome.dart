import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'generated_cover.dart';

const imageHeaders = {
  'User-Agent':
      'MotiScroll/1.0 (educational app; freely licensed Wikimedia portraits)',
};

Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return;
  }
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              },
        child: AnimatedScale(
          scale: _down && !reduce ? 0.97 : 1,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.text,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: sans(palette, 16, weight: FontWeight.w600, color: palette.bg),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Text(label, style: sans(palette, 16, weight: FontWeight.w600)),
      ),
    );
  }
}

class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? palette.accent : palette.border),
        ),
        child: Text(
          label,
          style: sans(
            palette,
            14,
            weight: FontWeight.w600,
            color: selected ? palette.accent : palette.text,
          ),
        ),
      ),
    );
  }
}

class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.following,
    required this.onPressed,
  });

  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final reduce = reduceMotion(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: following ? 'Following' : 'Follow',
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: following ? palette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: following ? palette.accent : palette.accent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                following ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(following),
                size: 18,
                color: following ? kInk : palette.accent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              following ? 'Following' : 'Follow',
              style: sans(
                palette,
                14,
                weight: FontWeight.w600,
                color: following ? kInk : palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpringIconButton extends StatefulWidget {
  const SpringIconButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onPressed,
    required this.label,
    this.activeColor,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onPressed;
  final String label;
  final Color? activeColor;

  @override
  State<SpringIconButton> createState() => _SpringIconButtonState();
}

class _SpringIconButtonState extends State<SpringIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final color = widget.active
        ? (widget.activeColor ?? palette.accent)
        : palette.text;
    return Pressable(
      semanticLabel: widget.label,
      onPressed: () {
        if (!reduceMotion(context)) _controller.forward(from: 0);
        widget.onPressed();
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.elasticOut.transform(_controller.value);
            return Transform.scale(scale: 0.84 + (0.16 * t), child: child);
          },
          child: Icon(widget.icon, size: 26, color: color),
        ),
      ),
    );
  }
}

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: 0.35 + (_controller.value * 0.4), child: child);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: palette.cardAlt,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.play, required this.child});

  final bool play;
  final Widget child;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _controller.value = 1;
  }

  @override
  void didUpdateWidget(RiseIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.play && !oldWidget.play) {
      _controller.forward(from: 0);
    } else if (!widget.play) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return Opacity(
          opacity: 0.72 + (0.28 * t),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({
    super.key,
    required this.author,
    required this.size,
    this.imageUrl,
    this.imageCredit,
    this.showPlay = false,
    this.onPlay,
  });

  final String author;
  final double size;
  final String? imageUrl;
  final ImageCredit? imageCredit;
  final bool showPlay;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final radius = BorderRadius.circular(size * 0.22);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: radius,
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              httpHeaders: imageHeaders,
              fit: BoxFit.cover,
              fadeInDuration: reduceMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              placeholder: (_, _) =>
                  SkeletonBox(width: size, height: size, radius: size * 0.22),
              errorWidget: (_, _, _) => _Initials(author: author, size: size),
            )
          : _Initials(author: author, size: size),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          imageCredit == null
              ? avatar
              : Pressable(
                  onPressed: () => showPhotoCredit(context, imageCredit!),
                  semanticLabel: 'Photo credit',
                  child: avatar,
                ),
          if (showPlay)
            Positioned(
              right: -2,
              bottom: -2,
              child: Pressable(
                onPressed: onPlay,
                semanticLabel: 'Read the text',
                child: Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.bg, width: 2),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: size * 0.22,
                    color: kInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.author, required this.size});

  final String author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors =
        coverPalettes[Field.values[hashString(author) % Field.values.length]]!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[0], colors[3]],
        ),
      ),
      child: Center(
        child: Text(
          initialsFor(author),
          style: serif(darkPalette, size * 0.34, color: kCream),
        ),
      ),
    );
  }
}

void showPhotoCredit(BuildContext context, ImageCredit credit) {
  final palette = AppScope.of(context).palette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
    ),
    builder: (context) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photo credit', style: serif(palette, 24)),
            const SizedBox(height: 16),
            Text(
              credit.artist,
              style: sans(palette, 16, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              credit.license,
              style: sans(palette, 14, color: palette.textMuted),
            ),
            const SizedBox(height: 16),
            Pressable(
              onPressed: () => openLink(credit.sourceUrl),
              semanticLabel: 'Open photo source',
              child: Text(
                'View source',
                style: sans(
                  palette,
                  15,
                  weight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
            ),
            if (credit.license.startsWith('CC BY')) ...[
              const SizedBox(height: 8),
              Pressable(
                onPressed: () =>
                    openLink('https://creativecommons.org/licenses/by/2.0/'),
                semanticLabel: 'Open license',
                child: Text(
                  'CC BY 2.0 license',
                  style: sans(
                    palette,
                    15,
                    weight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class PhotoCreditLine extends StatelessWidget {
  const PhotoCreditLine({super.key, required this.credit, this.maxLines});

  final ImageCredit credit;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: () => showPhotoCredit(context, credit),
      semanticLabel: 'Photo credit',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          'Photo: ${credit.artist} · ${credit.license}',
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          textAlign: maxLines == null ? TextAlign.start : TextAlign.center,
          style: sans(palette, 12, height: 1.3, color: palette.textFaint),
        ),
      ),
    );
  }
}

class SourceLine extends StatelessWidget {
  const SourceLine({super.key, required this.item, this.maxLines});

  final Item item;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final url = item.source.url;
    final text = Text(
      'Source · ${item.source.line}',
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: maxLines == null ? TextAlign.start : TextAlign.center,
      style: sans(palette, 13, height: 1.35, color: palette.textMuted),
    );
    if (url == null) return text;
    return Pressable(
      onPressed: () => openLink(url),
      semanticLabel: 'Open source',
      child: text,
    );
  }
}

class MotiMark extends StatelessWidget {
  const MotiMark({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Image.asset(
      'assets/images/mark.png',
      width: size,
      height: size,
      color: color ?? palette.text,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high,
    );
  }
}

class UnverifiedMark extends StatelessWidget {
  const UnverifiedMark({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Text(
      'Not verified',
      style: sans(palette, 12, weight: FontWeight.w600, color: palette.danger),
    );
  }
}
