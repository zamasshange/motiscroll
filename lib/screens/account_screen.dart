import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That could not be finished. Check the connection and try again.',
          ),
        ),
      );
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text('Account', style: serif(palette, 40, height: 1.05)),
          const SizedBox(height: 12),
          Text(
            state.remote
                ? 'You can read right away. Save your progress to keep the same library if you change phones.'
                : 'This copy is using the lines stored on the phone. Connect Firebase to save them to an account.',
            style: sans(palette, 15, color: palette.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            state.accountLabel ?? 'Not signed in',
            style: sans(palette, 13, color: palette.textFaint),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Continue with Apple',
            onPressed: !state.remote || _busy
                ? () {}
                : () => _run(
                    () => linkApple(state),
                    'Apple is linked to this library.',
                  ),
          ),
          const SizedBox(height: 8),
          OutlineButton(
            label: 'Continue with Google',
            onPressed: !state.remote || _busy
                ? () {}
                : () => _run(
                    () => linkGoogle(state),
                    'Google is linked to this library.',
                  ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email link'),
          ),
          const SizedBox(height: 8),
          OutlineButton(
            label: 'Email me a link',
            onPressed: !state.remote || _busy
                ? () {}
                : () => _run(
                    () => sendEmailLink(_email.text.trim()),
                    'The link was sent.',
                  ),
          ),
          const SizedBox(height: 24),
          OutlineButton(
            label: 'Sign out',
            onPressed: !state.remote || _busy
                ? () {}
                : () => _run(
                    () => signOutToAnonymous(state),
                    'Signed out. A new device library was started.',
                  ),
          ),
          const SizedBox(height: 8),
          OutlineButton(
            label: 'Delete account',
            onPressed: !state.remote || _busy
                ? () {}
                : () => _run(() async {
                    await deleteAccount();
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }, 'The account was deleted.'),
          ),
        ],
      ),
    );
  }
}
