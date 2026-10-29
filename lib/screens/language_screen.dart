import 'package:flutter/material.dart';

import '../l10n/languages.dart';
import '../l10n/ui_text.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';

String languageSettingLabel(AppState state, Locale device) {
  final code = state.uiLanguage ?? state.resolvedContentLanguage(device);
  final saved = state.contentLanguage;
  if (saved == null) {
    final resolved = languageByCode(state.resolvedContentLanguage(device));
    return '${ui(code, 'deviceLanguage')} · ${resolved?.nativeName ?? 'English'}';
  }
  final language = languageByCode(saved);
  if (language == null) return saved;
  return '${language.flag}  ${language.nativeName}';
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, this.backup = false});

  final bool backup;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final device = View.of(context).platformDispatcher.locale;
    final code = state.uiLanguage ?? state.resolvedContentLanguage(device);
    final primary = state.resolvedContentLanguage(device);
    final selected = backup ? state.secondLanguage : state.contentLanguage;
    final languages = languagesForPicker(device)
        .where((language) => !backup || language.code != primary)
        .toList();
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
            ui(code, backup ? 'backupLanguage' : 'language'),
            style: serif(palette, 36, height: 1.05),
          ),
          const SizedBox(height: 12),
          Text(
            ui(code, backup ? 'backupExplain' : 'chooseLanguage'),
            style: sans(palette, 15, height: 1.35, color: palette.textMuted),
          ),
          const SizedBox(height: 20),
          if (!backup)
            _LanguageRow(
              flag: languageByCode(primary)?.flag ?? '🇬🇧',
              title: ui(code, 'deviceLanguage'),
              subtitle: languageByCode(primary)?.nativeName ?? 'English',
              selected: state.contentLanguage == null,
              onTap: () => state.setContentLanguage(null),
            )
          else
            _LanguageRow(
              flag: '🇬🇧',
              title: ui(code, 'englishOnly'),
              subtitle: ui(code, 'noBackup'),
              selected: state.secondLanguage == null,
              onTap: () => state.setSecondLanguage(null),
            ),
          for (final language in languages)
            _LanguageRow(
              flag: language.flag,
              title: language.nativeName,
              subtitle: language.englishName,
              selected: selected == language.code,
              onTap: () {
                if (backup) {
                  state.setSecondLanguage(language.code);
                } else {
                  state.setContentLanguage(language.code);
                }
              },
            ),
          if (!backup) ...[
            const SizedBox(height: 28),
            _BackupLink(
              code: code,
              label: state.secondLanguage == null
                  ? 'English'
                  : languageByCode(state.secondLanguage)?.nativeName ??
                        'English',
              flag: state.secondLanguage == null
                  ? '🇬🇧'
                  : languageByCode(state.secondLanguage)?.flag ?? '🇬🇧',
            ),
          ],
        ],
      ),
    );
  }
}

class _BackupLink extends StatelessWidget {
  const _BackupLink({
    required this.code,
    required this.label,
    required this.flag,
  });

  final String code;
  final String label;
  final String flag;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const LanguageScreen(backup: true),
          ),
        );
      },
      semanticLabel: ui(code, 'backupLanguage'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ui(code, 'backupLanguage'), style: sans(palette, 17)),
                  const SizedBox(height: 2),
                  Text(
                    ui(code, 'backupDetail'),
                    style: sans(palette, 13, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(label, style: sans(palette, 14, color: palette.textFaint)),
            Icon(Icons.chevron_right_rounded, color: palette.textFaint),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(flag, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: sans(palette, 17)),
                  if (subtitle != title)
                    Text(
                      subtitle,
                      style: sans(palette, 13, color: palette.textMuted),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: palette.accent),
          ],
        ),
      ),
    );
  }
}
