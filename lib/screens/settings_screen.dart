import 'package:flutter/material.dart';

import '../l10n/ui_text.dart';
import '../l10n/widget_gallery.dart';
import '../services/reminders.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'account_screen.dart';
import 'language_screen.dart';
import 'legal_screen.dart';

const kAppVersion = 'v1.0.0 (1)';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final linked =
        state.accountLabel != null &&
        state.accountLabel != 'Saved on this device';
    final device = View.of(context).platformDispatcher.locale;
    final code = state.uiLanguage ?? state.resolvedContentLanguage(device);
    return _SettingsPage(
      title: ui(code, 'settings'),
      children: [
        _Chevron(
          title: ui(code, 'account'),
          value: linked ? state.accountLabel : null,
          onTap: () => _push(context, const AccountScreen()),
        ),
        _Chevron(
          title: ui(code, 'language'),
          value: languageSettingLabel(state, device),
          onTap: () => _push(context, const LanguageScreen()),
        ),
        _Chevron(
          title: ui(code, 'general'),
          onTap: () => _push(context, const GeneralSettingsScreen()),
        ),
        _Chevron(
          title: widgetString(code, 'widgets'),
          onTap: () => _push(context, const WidgetsSettingsScreen()),
        ),
        _Chevron(
          title: ui(code, 'support'),
          onTap: () => _push(context, const SupportScreen()),
        ),
        _Chevron(
          title: ui(code, 'legal'),
          onTap: () => _push(context, const LegalHubScreen()),
        ),
        const SizedBox(height: 32),
        if (!linked)
          PrimaryButton(
            label: 'Sign in',
            onPressed: () => _push(context, const AccountScreen()),
          ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            kAppVersion,
            style: sans(palette, 12, color: palette.textFaint),
          ),
        ),
      ],
    );
  }
}

class WidgetsSettingsScreen extends StatelessWidget {
  const WidgetsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final code = state.uiLanguage ??
        state.resolvedContentLanguage(
          View.of(context).platformDispatcher.locale,
        );
    final body = sans(palette, 15, height: 1.4, color: palette.textMuted);
    return _SettingsPage(
      title: widgetString(code, 'widgets'),
      children: [
        Text(widgetString(code, 'iosWidgetHelp'), style: body),
        const SizedBox(height: 16),
        Text(widgetString(code, 'androidWidgetHelp'), style: body),
        const SizedBox(height: 8),
        _Toggle(
          title: widgetString(code, 'showSavedLock'),
          subtitle: widgetString(code, 'showSavedLockDetail'),
          value: state.showSavedOnLockScreen,
          onChanged: state.setShowSavedOnLockScreen,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: widgetString(code, 'refreshWidgets'),
          onPressed: state.syncWidgets,
        ),
      ],
    );
  }
}

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  var _busy = false;

  Future<void> _toggleReminder(bool value) async {
    final state = AppScope.of(context);
    setState(() => _busy = true);
    if (value) {
      final ok = await scheduleDailyReminder();
      if (!mounted) return;
      state.setReminder(ok);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The reminder was not scheduled.')),
        );
      }
    } else {
      await cancelDailyReminder();
      if (!mounted) return;
      state.setReminder(false);
    }
    if (mounted) setState(() => _busy = false);
  }

  String _themeLabel(AppState state) {
    if (state.followSystemTheme) return 'System';
    return state.dark ? 'Dark' : 'Light';
  }

  void _pickTheme() {
    final state = AppScope.of(context);
    _choose(
      context,
      title: 'Switch theme',
      options: const ['System', 'Light', 'Dark'],
      selected: _themeLabel(state),
      onSelected: (choice) {
        if (choice == 'System') {
          final brightness = MediaQuery.platformBrightnessOf(context);
          state.followSystem(brightness == Brightness.dark);
        } else {
          state.setDark(choice == 'Dark');
        }
      },
    );
  }

  void _pickFontSize() {
    final state = AppScope.of(context);
    _choose(
      context,
      title: 'Font size',
      options: const ['Default (recommended)', 'Large'],
      selected: state.largeText ? 'Large' : 'Default (recommended)',
      onSelected: (choice) => state.setLargeText(choice == 'Large'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _SettingsPage(
      title: 'General',
      children: [
        _Chevron(
          title: 'Switch theme',
          value: _themeLabel(state),
          onTap: _pickTheme,
        ),
        _Chevron(
          title: 'Font size',
          value: state.largeText ? 'Large' : 'Default (recommended)',
          onTap: _pickFontSize,
        ),
        _Toggle(
          title: 'Daily reminder',
          subtitle: 'A local nudge at 8:00',
          value: state.reminderOn,
          onChanged: _busy ? null : _toggleReminder,
        ),
        _Chevron(
          title: 'Replay onboarding',
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            state.replayOnboarding();
          },
        ),
        _Chevron(
          title: 'Reset saved progress',
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset saved progress?'),
                content: const Text(
                  'Likes, saves, notes, follows, and the streak on this device are cleared.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            state.resetProgress();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved progress was cleared.')),
            );
          },
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const topics = [
    'A quote looks wrong or misattributed',
    'A source or photo credit is wrong',
    'Suggest a person for the library',
    'Sign-in or account problem',
    'Something else',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return _SettingsPage(
      title: 'Contact & Support',
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              'Hi! What do you need help with?',
              style: sans(palette, 15),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final topic in topics) ...[
          Pressable(
            onPressed: () => _push(context, _MessageScreen(topic: topic)),
            semanticLabel: topic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(topic, style: sans(palette, 15))),
                  Icon(Icons.chevron_right_rounded, color: palette.textFaint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MessageScreen extends StatefulWidget {
  const _MessageScreen({required this.topic});

  final String topic;

  @override
  State<_MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<_MessageScreen> {
  final _text = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty) return;
    setState(() => _sending = true);
    final ok = await AppScope.of(context).sendFeedback(widget.topic, message);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sent. An editor reads every message.'
              : 'The message was not sent. Check the connection and try again.',
        ),
      ),
    );
    if (ok && mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return _SettingsPage(
      title: 'Message',
      children: [
        Text(widget.topic, style: sans(palette, 15, color: palette.textMuted)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: TextField(
            controller: _text,
            minLines: 6,
            maxLines: 12,
            maxLength: 1500,
            autofocus: true,
            style: sans(palette, 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Tell us what happened. Add the quote or person if it is about one.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _sending ? 'Sending' : 'Send',
          onPressed: _sending ? () {} : _send,
        ),
      ],
    );
  }
}

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Legal',
      children: [
        _Chevron(
          title: 'Privacy Policy',
          onTap: () =>
              _push(context, const LegalScreen(kind: LegalKind.privacy)),
        ),
        _Chevron(
          title: 'Terms of Service',
          onTap: () => _push(context, const LegalScreen(kind: LegalKind.terms)),
        ),
        _Chevron(
          title: 'Rights and sources',
          onTap: () =>
              _push(context, const LegalScreen(kind: LegalKind.rights)),
        ),
        _Chevron(
          title: 'Photo credits',
          onTap: () => _push(context, const PhotoCreditsScreen()),
        ),
      ],
    );
  }
}

class PhotoCreditsScreen extends StatelessWidget {
  const PhotoCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final credits = <String, (String, String)>{};
    for (final author in state.authors) {
      final credit = author.imageCredit;
      if (credit != null) {
        credits[author.name] = (credit.artist, credit.license);
      }
    }
    for (final item in state.items) {
      final credit = item.imageCredit;
      if (credit != null) {
        credits[item.author] = (credit.artist, credit.license);
      }
    }
    final names = credits.keys.toList()..sort();
    return _SettingsPage(
      title: 'Photo credits',
      children: [
        Text(
          'Portraits come from Wikimedia Commons under the license shown.',
          style: sans(palette, 14, color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        if (names.isEmpty)
          Text(
            'Credits appear here once the library loads.',
            style: sans(palette, 15, color: palette.textMuted),
          ),
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: sans(palette, 15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${credits[name]!.$1} · ${credits[name]!.$2}',
                  style: sans(palette, 13, color: palette.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

void _choose(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String selected,
  required ValueChanged<String> onSelected,
}) {
  final palette = AppScope.of(context).palette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: serif(palette, 26)),
            const SizedBox(height: 8),
            for (final option in options)
              Pressable(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(option);
                },
                semanticLabel: option,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(child: Text(option, style: sans(palette, 17))),
                      if (option == selected)
                        Icon(Icons.check_rounded, color: palette.accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
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
          Text(title, style: serif(palette, 36, height: 1.05)),
          const SizedBox(height: 24),
          ...children,
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
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

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
