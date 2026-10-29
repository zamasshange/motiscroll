import 'package:flutter/material.dart';

import '../notifications/notification_prefs.dart';
import '../notifications/notification_service.dart';
import '../notifications/notification_text.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'onboarding_previews.dart';

class NotificationOffer extends StatelessWidget {
  const NotificationOffer({
    super.key,
    required this.busy,
    required this.prefs,
    required this.onPrefs,
    required this.onTurnOn,
    required this.onSkip,
    this.onBack,
    this.showBack = true,
  });

  final bool busy;
  final NotificationPrefs prefs;
  final ValueChanged<NotificationPrefs> onPrefs;
  final VoidCallback onTurnOn;
  final VoidCallback onSkip;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final device = View.of(context).platformDispatcher.locale;
    final code = state.uiLanguage ?? state.resolvedContentLanguage(device);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final morning = formatClockTime(prefs.morningTime, code);
    final evening = formatClockTime(prefs.eveningTime, code);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            Pressable(
              onPressed: busy ? null : onBack,
              semanticLabel: 'Back',
              child: Text(
                'Back',
                style: sans(
                  palette,
                  15,
                  weight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const OnboardNotificationPreview(),
                const SizedBox(height: 20),
                Text(
                  notifyUi(code, 'offerTitle'),
                  style: serif(palette, 32, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  notifyUi(code, 'offerBody')
                      .replaceAll('{morning}', morning)
                      .replaceAll('{evening}', evening),
                  style: sans(
                    palette,
                    16,
                    height: 1.4,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                _SlotRow(
                  title: notifyUi(code, 'morning'),
                  time: morning,
                  value: prefs.morningEnabled,
                  onChanged: (on) =>
                      onPrefs(prefs.copyWith(morningEnabled: on)),
                  onTime: () => _pickTime(
                    context,
                    prefs.morningClock,
                    (clock) => onPrefs(prefs.copyWith(morningTime: clock.hhmm)),
                  ),
                ),
                _SlotRow(
                  title: notifyUi(code, 'evening'),
                  time: evening,
                  value: prefs.eveningEnabled,
                  onChanged: (on) =>
                      onPrefs(prefs.copyWith(eveningEnabled: on)),
                  onTime: () => _pickTime(
                    context,
                    prefs.eveningClock,
                    (clock) => onPrefs(prefs.copyWith(eveningTime: clock.hhmm)),
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            label: busy ? 'One moment' : notifyUi(code, 'turnOn'),
            onPressed: busy ? () {} : onTurnOn,
          ),
          const SizedBox(height: 8),
          OutlineButton(
            label: notifyUi(code, 'notNow'),
            onPressed: busy ? () {} : onSkip,
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.title,
    required this.time,
    required this.value,
    required this.onChanged,
    required this.onTime,
  });

  final String title;
  final String time;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onPressed: onTime,
              semanticLabel: title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: sans(palette, 17, weight: FontWeight.w600),
                  ),
                  Text(
                    time,
                    style: sans(palette, 14, color: palette.textMuted),
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

Future<void> _pickTime(
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
