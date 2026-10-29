import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../notifications/notification_prefs.dart';
import '../notifications/notification_service.dart';
import '../notifications/notification_text.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'notification_offer.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final device = View.of(context).platformDispatcher.locale;
    final code =
        state.uiLanguage ?? state.resolvedContentLanguage(device);
    final prefs = state.notificationPrefs;
    final body = sans(palette, 15, height: 1.4, color: palette.textMuted);
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        elevation: 0,
        title: const SizedBox.shrink(),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Text(
            notifyUi(code, 'notifications'),
            style: serif(palette, 36, height: 1.05),
          ),
          const SizedBox(height: 16),
          _Banner(
            text: state.notificationPermissionGranted
                ? notifyUi(code, 'notificationsOn')
                : notifyUi(code, 'notificationsOff'),
            action: notifyUi(code, 'openSystemSettings'),
            onAction: () => NotificationService.instance.openSystemSettings(),
          ),
          const SizedBox(height: 8),
          _Toggle(
            title: notifyUi(code, 'morning'),
            subtitle: formatClockTime(prefs.morningTime, code),
            value: prefs.morningEnabled,
            onChanged: (on) => state.setNotificationPrefs(
              prefs.copyWith(morningEnabled: on),
            ),
            onSubtitle: () => _pick(
              context,
              prefs.morningClock,
              (clock) => state.setNotificationPrefs(
                prefs.copyWith(morningTime: clock.hhmm),
              ),
            ),
          ),
          _Toggle(
            title: notifyUi(code, 'evening'),
            subtitle: formatClockTime(prefs.eveningTime, code),
            value: prefs.eveningEnabled,
            onChanged: (on) => state.setNotificationPrefs(
              prefs.copyWith(eveningEnabled: on),
            ),
            onSubtitle: () => _pick(
              context,
              prefs.eveningClock,
              (clock) => state.setNotificationPrefs(
                prefs.copyWith(eveningTime: clock.hhmm),
              ),
            ),
          ),
          _Chevron(
            title: notifyUi(code, 'whatToSend'),
            value: _sourceLabel(code, prefs.quoteSource),
            onTap: () => _chooseSource(context, state, code),
          ),
          if (prefs.pausedUntil != null)
            _Chevron(
              title: notifyUi(code, 'resume'),
              onTap: () => state.setNotificationPrefs(
                prefs.copyWith(clearPausedUntil: true),
              ),
            )
          else
            _Chevron(
              title: notifyUi(code, 'pauseWeek'),
              onTap: () {
                final until = DateTime.now().add(const Duration(days: 7));
                state.setNotificationPrefs(
                  prefs.copyWith(pausedUntil: dayKey(until)),
                );
              },
            ),
          _Chevron(
            title: notifyUi(code, 'openSystemSettings'),
            onTap: () => NotificationService.instance.openSystemSettings(),
          ),
          const SizedBox(height: 16),
          Text(notifyUi(code, 'capNote'), style: body),
          const SizedBox(height: 8),
          Text(notifyUi(code, 'lockScreenNote'), style: body),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            _Chevron(
              title: notifyUi(code, 'plannedNotifications'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PlannedNotificationsScreen(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PlannedNotificationsScreen extends StatelessWidget {
  const PlannedNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final code =
        state.uiLanguage ??
        state.resolvedContentLanguage(
          View.of(context).platformDispatcher.locale,
        );
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: NotificationService.instance.loadPlan(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Text(
                notifyUi(code, 'plannedNotifications'),
                style: serif(palette, 32, height: 1.1),
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                Text(
                  'Nothing is scheduled.',
                  style: sans(palette, 15, color: palette.textMuted),
                ),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '${row.date}  ${row.slot.name}  ${row.itemId}',
                    style: sans(palette, 14, color: palette.textMuted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationAskSheet extends StatelessWidget {
  const NotificationAskSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: state.palette.bg,
      body: NotificationOffer(
        busy: false,
        showBack: false,
        prefs: state.notificationPrefs,
        onPrefs: state.setNotificationPrefs,
        onTurnOn: () async {
          await state.enableNotifications();
          if (context.mounted) Navigator.of(context).pop();
        },
        onSkip: () {
          state.dismissNotificationAsk();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

Future<void> _pick(
  BuildContext context,
  ClockTime current,
  ValueChanged<ClockTime> onPicked,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
  );
  if (picked == null) return;
  onPicked(ClockTime(picked.hour, picked.minute));
}

String _sourceLabel(String code, QuoteSource source) {
  return switch (source) {
    QuoteSource.followedFields => notifyUi(code, 'followedFields'),
    QuoteSource.all => notifyUi(code, 'everything'),
    QuoteSource.mood => notifyUi(code, 'aMood'),
  };
}

void _chooseSource(BuildContext context, AppState state, String code) {
  final palette = state.palette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notifyUi(code, 'whatToSend'), style: serif(palette, 26)),
            const SizedBox(height: 8),
            for (final source in QuoteSource.values)
              Pressable(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  state.setNotificationPrefs(
                    state.notificationPrefs.copyWith(quoteSource: source),
                  );
                },
                semanticLabel: _sourceLabel(code, source),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _sourceLabel(code, source),
                    style: sans(palette, 17),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: sans(palette, 15)),
          const SizedBox(height: 8),
          Pressable(
            onPressed: onAction,
            semanticLabel: action,
            child: Text(
              action,
              style: sans(palette, 14, weight: FontWeight.w600, color: palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.onSubtitle,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onSubtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onPressed: onSubtitle,
              semanticLabel: title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: sans(palette, 17)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: sans(palette, 13, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: palette.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.title, required this.onTap, this.value});

  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: sans(palette, 17))),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: sans(palette, 14, color: palette.textFaint),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: palette.textFaint),
          ],
        ),
      ),
    );
  }
}
