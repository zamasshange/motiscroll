import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

void showHabit(BuildContext context) {
  final state = AppScope.of(context);
  final palette = state.palette;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday % 7));
      final days = List.generate(7, (i) => start.add(Duration(days: i)));
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  final box = context.findRenderObject();
                  Rect? origin;
                  if (box is RenderBox && box.hasSize) {
                    origin = box.localToGlobal(Offset.zero) & box.size;
                  }
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          '${state.streak} day streak in $kAppName. A streak counts a day you actually open a line.',
                      sharePositionOrigin: origin,
                    ),
                  );
                },
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ),
            Text(
              'A streak counts a day you actually open a line.',
              style: sans(palette, 28, height: 1.15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Days opened',
                    value: '${state.streak}',
                    detail: 'Best ${state.bestStreak}',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: 'Lines read',
                    value: '${state.read.length}',
                    detail: '${state.visitDays.length} days marked',
                    icon: Icons.menu_book_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                state.streak == 1
                    ? '1 day in a row'
                    : '${state.streak} days in a row',
                style: sans(palette, 16, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _weekday(day.weekday),
                          style: sans(palette, 11, color: palette.textFaint),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _sameDay(day, now)
                                ? palette.accent
                                : state.visitDays.contains(_key(day))
                                ? palette.accentSoft
                                : const Color(0x00000000),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: sans(
                              palette,
                              13,
                              weight: FontWeight.w600,
                              color: _sameDay(day, now) ? kInk : palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

String _weekday(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _key(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: sans(palette, 13, color: palette.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: sans(palette, 32, weight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(icon, color: palette.accent, size: 22),
            ],
          ),
          Text(detail, style: sans(palette, 12, color: palette.textFaint)),
        ],
      ),
    );
  }
}
