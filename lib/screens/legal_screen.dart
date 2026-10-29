import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

enum LegalKind { rights, privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});

  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final copy = switch (kind) {
      LegalKind.rights => (
        'Rights and sources',
        'Lines are published only after an editor checks them against the original work. '
            'Wikiquote is a discovery aid and is credited under CC BY-SA 4.0. It is never the approving source. '
            'Author photos come from Wikimedia Commons and are limited to public domain, CC0, CC BY, and CC BY-SA. '
            'A photo that requires attribution always shows that credit. '
            'Moti Scroll is not affiliated with or endorsed by the people, estates, or publishers named in the library. '
            'Speeches are not hosted here. Watch full speech opens the official page. '
            'Use Report this line for a wrong attribution, a wrong text, or anything that should not be up.',
      ),
      LegalKind.privacy => (
        'Privacy',
        'Placeholder for lawyer review. The app stores your library, likes, saves, follows, and streak in Firebase under your account. '
            'Anonymous sign-in creates that account on the device. Linking Apple, Google, or email keeps the same account. '
            'Home screen and lock screen widgets keep a copy of quote text, the author, the streak, and saved lines in an App Group on this phone. That copy has no email, user id, or sign-in token. Saved lines are not shown on a lock screen widget. A setting records whether you would allow that, and it stays off until you turn it on. '
            'Delete account removes the library and the login, and clears the widget copy. Crash reports may be sent so the app can be fixed. '
            'There are no advertising or tracking SDKs. Quote text is not sold.',
      ),
      LegalKind.terms => (
        'Terms',
        'Placeholder for lawyer review. The library is offered as a reading aid. '
            'Public-domain texts stay in the public domain. Credits and licenses on photos still apply. '
            'Do not treat a line as verified until it is published. Character collections stay off.',
      ),
    };
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
          Text(copy.$1, style: serif(palette, 40, height: 1.05)),
          const SizedBox(height: 16),
          Text(copy.$2, style: sans(palette, 16, height: 1.45)),
        ],
      ),
    );
  }
}
