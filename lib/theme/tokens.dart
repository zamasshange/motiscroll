import 'package:flutter/widgets.dart';

const kAppName = 'Moti Scroll';
const kTabBarHeight = 62.0;
const kTabBarFloat = 10.0;
const kCardRadius = 24.0;
const kSheetRadius = 28.0;

class Palette {
  const Palette({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.accentSoft,
    required this.danger,
    required this.tabBar,
    required this.sheet,
    required this.backdrop,
  });

  final Color bg;
  final Color card;
  final Color cardAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color accentSoft;
  final Color danger;
  final Color tabBar;
  final Color sheet;
  final Color backdrop;
}

const darkPalette = Palette(
  bg: Color(0xFF0B0B0D),
  card: Color(0xFF16161A),
  cardAlt: Color(0xFF1E1E24),
  border: Color(0x14FFFFFF),
  text: Color(0xFFF4F1EA),
  textMuted: Color(0xFFA8A197),
  textFaint: Color(0xFF726C64),
  accent: Color(0xFFE07A4A),
  accentSoft: Color(0x29E07A4A),
  danger: Color(0xFFE15D5D),
  tabBar: Color(0xE0121216),
  sheet: Color(0xFF141418),
  backdrop: Color(0x94000000),
);

const lightPalette = Palette(
  bg: Color(0xFFF3F3F5),
  card: Color(0xFFFFFFFF),
  cardAlt: Color(0xFFEEEEF1),
  border: Color(0x14000000),
  text: Color(0xFF111111),
  textMuted: Color(0xFF8A8A8E),
  textFaint: Color(0xFFB4B4B8),
  accent: Color(0xFFC4622D),
  accentSoft: Color(0x1FC4622D),
  danger: Color(0xFFC43B3B),
  tabBar: Color(0xF7FFFFFF),
  sheet: Color(0xFFFFFFFF),
  backdrop: Color(0x591C1610),
);

const kInk = Color(0xFF1C1916);
const kCream = Color(0xFFF4F1EA);

TextStyle serif(
  Palette palette,
  double size, {
  double height = 1.15,
  FontWeight weight = FontWeight.w600,
  Color? color,
  FontStyle style = FontStyle.normal,
}) {
  return TextStyle(
    fontFamily: 'Playfair',
    fontSize: size,
    height: height,
    fontWeight: weight,
    fontStyle: style,
    color: color ?? palette.text,
  );
}

TextStyle sans(
  Palette palette,
  double size, {
  double height = 1.35,
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'DMSans',
    fontSize: size,
    height: height,
    fontWeight: weight,
    color: color ?? palette.text,
  );
}

double dockInset(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom +
      kTabBarHeight +
      kTabBarFloat +
      36;
}

bool reduceMotion(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}
