import 'package:flutter/material.dart';

import '../services/reminders.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'account_screen.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
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
          Text('Settings', style: serif(palette, 40, height: 1.05)),
          const SizedBox(height: 28),
          _Row(
            title: 'Appearance',
            subtitle: state.dark ? 'Dark' : 'Light',
            trailing: Switch.adaptive(
              value: state.dark,
              onChanged: state.setDark,
            ),
          ),
          _Row(
            title: 'Daily reminder',
            subtitle: 'Local, at 8:00',
            trailing: Switch.adaptive(
              value: state.reminderOn,
              onChanged: _busy ? null : _toggleReminder,
            ),
          ),
          _Chevron(
            title: 'Account',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
            ),
          ),
          _Chevron(
            title: 'Rights and sources',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(kind: LegalKind.rights),
              ),
            ),
          ),
          _Chevron(
            title: 'Privacy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(kind: LegalKind.privacy),
              ),
            ),
          ),
          _Chevron(
            title: 'Terms',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(kind: LegalKind.terms),
              ),
            ),
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
            onTap: () {
              state.resetProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Likes, saves, follows, and the streak were cleared.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
          trailing,
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: sans(palette, 17))),
            Icon(Icons.chevron_right_rounded, color: palette.textFaint),
          ],
        ),
      ),
    );
  }
}
