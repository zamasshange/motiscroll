import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';

class StudyPage extends StatelessWidget {
  const StudyPage({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = state.palette;
    final read = state.read.contains(item.id);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                _RoundIcon(
                  icon: read ? Icons.check_circle : Icons.check_circle_outline,
                  label: read ? 'Marked read' : 'Mark read',
                  onTap: () {
                    state.toggleRead(item.id);
                    Navigator.of(context).pop();
                  },
                ),
                const Spacer(),
                _RoundIcon(
                  icon: Icons.close_rounded,
                  label: 'Close',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _FieldPill(label: fieldInfo[item.field]!.title)),
            const SizedBox(height: 16),
            Text(
              item.author,
              textAlign: TextAlign.center,
              style: serif(palette, 34, height: 1.1),
            ),
            const SizedBox(height: 6),
            Text(
              item.authorRole,
              textAlign: TextAlign.center,
              style: sans(palette, 13, color: palette.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.cardAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                style: serif(
                  palette,
                  18,
                  height: 1.4,
                  style: FontStyle.italic,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: SourceLine(item: item)),
            if (!item.verified) ...[
              const SizedBox(height: 8),
              const Center(child: UnverifiedMark()),
            ],
            if (item.imageCredit != null) ...[
              const SizedBox(height: 12),
              Center(
                child: AuthorAvatar(
                  author: item.author,
                  size: 72,
                  imageUrl: item.imageUrl,
                  imageCredit: item.imageCredit,
                ),
              ),
              PhotoCreditLine(credit: item.imageCredit!),
            ],
            const SizedBox(height: 8),
            Divider(color: palette.border, height: 32),
            _Section(
              title: 'Context',
              body: item.deeper.context,
              onCopy: () => _copy(context, item.deeper.context),
            ),
            const SizedBox(height: 16),
            _TintedSection(
              title: 'Did you know',
              body: item.deeper.didYouKnow,
              onCopy: () => _copy(context, item.deeper.didYouKnow),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Takeaway',
              body: item.deeper.takeaway,
              onCopy: () => _copy(context, item.deeper.takeaway),
            ),
            const SizedBox(height: 8),
            Center(
              child: Pressable(
                onPressed: () => _report(context, item),
                semanticLabel: 'Report this line',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Report this line',
                    style: sans(
                      palette,
                      14,
                      weight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final related
                    in item.deeper.related
                        .map((id) => itemById(id, AppScope.of(context).items))
                        .whereType<Item>())
                  ChoiceChipButton(
                    label: related.author,
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => StudyPage(item: related),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _report(BuildContext context, Item item) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppScope.of(context).palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final palette = AppScope.of(context).palette;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final label in [
                'Wrong attribution',
                'Wrong text',
                'Inappropriate',
              ])
                ListTile(
                  title: Text(label, style: sans(palette, 16)),
                  onTap: () => Navigator.of(context).pop(label),
                ),
            ],
          ),
        );
      },
    );
    if (reason == null || !context.mounted) return;
    try {
      await AppScope.of(context).reportItem(item.id, reason, '');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved on this account.')),
      );
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The report could not be saved.')),
      );
    }
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied')));
  }
}

void openStudy(BuildContext context, Item item) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => StudyPage(item: item)));
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Pressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: palette.card,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: 20, color: palette.text),
      ),
    );
  }
}

class _FieldPill extends StatelessWidget {
  const _FieldPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: sans(
          palette,
          12,
          weight: FontWeight.w600,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    required this.onCopy,
  });

  final String title;
  final String body;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: sans(
                palette,
                12,
                weight: FontWeight.w600,
                color: palette.textFaint,
              ),
            ),
            const Spacer(),
            Pressable(
              onPressed: onCopy,
              semanticLabel: 'Copy $title',
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: palette.textFaint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(body, style: sans(palette, 16, height: 1.45)),
      ],
    );
  }
}

class _TintedSection extends StatelessWidget {
  const _TintedSection({
    required this.title,
    required this.body,
    required this.onCopy,
  });

  final String title;
  final String body;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: sans(
                  palette,
                  12,
                  weight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
              const Spacer(),
              Pressable(
                onPressed: onCopy,
                semanticLabel: 'Copy $title',
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: palette.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: sans(palette, 15, height: 1.4)),
        ],
      ),
    );
  }
}
