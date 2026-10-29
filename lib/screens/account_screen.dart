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
  final _password = TextEditingController();
  var _busy = false;
  var _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    } on AccountException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
            state.firebaseReady
                ? 'You can read right away. Save your progress to keep the same library if you change phones.'
                : (state.accountError ??
                      'The account service is not connected yet.'),
            style: sans(palette, 15, color: palette.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            state.accountLabel ?? 'Not signed in',
            style: sans(palette, 13, color: palette.textFaint),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Continue with Google',
            onPressed: _busy
                ? () {}
                : () => _run(
                    () => linkGoogle(state),
                    'Google is linked to this library.',
                  ),
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _password,
            label: 'Password',
            obscure: _hidePassword,
            trailing: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Sign in',
            onPressed: _busy
                ? () {}
                : () => _run(
                    () => signInWithEmailPassword(
                      state,
                      _email.text.trim(),
                      _password.text,
                    ),
                    'Signed in.',
                  ),
          ),
          const SizedBox(height: 8),
          OutlineButton(
            label: 'Create account',
            onPressed: _busy
                ? () {}
                : () => _run(
                    () => createEmailAccount(
                      state,
                      _email.text.trim(),
                      _password.text,
                    ),
                    'The account was created.',
                  ),
          ),
          const SizedBox(height: 24),
          OutlineButton(
            label: 'Sign out',
            onPressed: _busy
                ? () {}
                : () => _run(
                    () => signOutToAnonymous(state),
                    'Signed out. A new device library was started.',
                  ),
          ),
          const SizedBox(height: 8),
          OutlineButton(
            label: 'Delete account',
            onPressed: _busy
                ? () {}
                : () => _run(() async {
                    await deleteAccount();
                    await state.clearWidgets();
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }, 'The account was deleted.'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: sans(palette, 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: sans(palette, 13, color: palette.textMuted),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}
