import 'package:flutter/material.dart';

enum ShareMark { whatsapp, instagram, facebook, tiktok, x }

class ShareBrandMark extends StatelessWidget {
  const ShareBrandMark(this.mark, {super.key, this.size = 36});

  final ShareMark mark;
  final double size;

  String get _asset {
    return switch (mark) {
      ShareMark.whatsapp => 'assets/share/whatsapp.png',
      ShareMark.instagram => 'assets/share/instagram.png',
      ShareMark.facebook => 'assets/share/facebook.png',
      ShareMark.tiktok => 'assets/share/tiktok.png',
      ShareMark.x => 'assets/share/x.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}
