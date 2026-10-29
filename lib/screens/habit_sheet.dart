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
                    label: 'Weeks in a row',
                    value: '${weeksInARow(state.visitDays, now)}',
                    detail:
                        'Best day streak ${state.bestStreak > state.streak ? state.bestStreak : state.streak}',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: 'Days this year',
                    value:
                        '${state.visitDays.where((day) => day.startsWith('${now.year}-')).length}',
                    detail: state.visitDays.length == 1
                        ? '1 day in total'
                        : '${state.visitDays.length} days in total',
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LibraryProgress(
              read: state.readInLibrary,
              total: state.items.length,
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

/// Consecutive Sunday-start weeks with at least one opened day, counting
/// back from this week. An empty current week does not break the run.
int weeksInARow(Set<String> visitDays, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  var weekStart = today.subtract(Duration(days: today.weekday % 7));
  bool visited(DateTime start) => List.generate(
    7,
    (i) => _key(start.add(Duration(days: i))),
  ).any(visitDays.contains);
  if (!visited(weekStart)) {
    weekStart = weekStart.subtract(const Duration(days: 7));
  }
  var count = 0;
  while (visited(weekStart)) {
    count++;
    weekStart = weekStart.subtract(const Duration(days: 7));
  }
  return count;
}

class _LibraryProgress extends StatelessWidget {
  const _LibraryProgress({required this.read, required this.total});

  final int read;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final share = total == 0 ? 0.0 : read / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Library read',
                  style: sans(palette, 13, color: palette.textMuted),
                ),
              ),
              Text(
                '${(share * 100).round()}%',
                style: sans(palette, 13, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$read of $total lines loaded',
            style: sans(palette, 12, color: palette.textFaint),
          ),
        ],
      ),
    );
  }
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
