import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/reminders.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _page = PageController();
  late final AnimationController _art = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  var _index = 0;
  var _seeded = false;
  var _busy = false;
  final _fields = <Field>{};
  Mood? _mood;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      final state = AppScope.of(context);
      _fields.addAll(state.followed);
      _mood = state.usualMood;
      _seeded = true;
    }
    _syncArt();
  }

  void _syncArt() {
    final valuePage = _index >= 1 && _index <= 3;
    if (reduceMotion(context) || !valuePage) {
      _art.stop();
      _art.value = 1;
    } else if (!_art.isAnimating) {
      _art.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _art.dispose();
    super.dispose();
  }

  void _go(int page) {
    final reduce = reduceMotion(context);
    _page.animateToPage(
      page,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish({required bool reminder}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppScope.of(context);
    if (reminder) {
      final ok = await scheduleDailyReminder();
      if (!mounted) return;
      state.setReminder(ok);
    }
    state.completeOnboarding(fields: _fields, mood: _mood);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Scaffold(
      backgroundColor: palette.bg,
      body: PageView(
        controller: _page,
        onPageChanged: (index) => setState(() {
          _index = index;
          _syncArt();
        }),
        children: [
          _Welcome(onStart: () => _go(1)),
          _ValuePage(
            art: _ValueArt(index: 0, animation: _art),
            title: 'Scroll with purpose',
            body: 'One passage at a time, long enough to read and short enough to keep.',
            showSkip: true,
            onNext: () => _go(2),
            onSkip: () => _go(4),
            page: 0,
          ),
          _ValuePage(
            art: _ValueArt(index: 1, animation: _art),
            title: 'Go deeper on any quote',
            body: 'Context, a fact, and a next step sit behind the line. The source stays in view.',
            showSkip: true,
            onNext: () => _go(3),
            onSkip: () => _go(4),
            page: 1,
          ),
          _ValuePage(
            art: _ValueArt(index: 2, animation: _art),
            title: 'Build a daily habit',
            body: 'Pick a mood, follow a field, and let a streak count only when you actually open a line.',
            showSkip: true,
            onNext: () => _go(4),
            onSkip: () => _go(4),
            page: 2,
          ),
          _Personalize(
            fields: _fields,
            mood: _mood,
            onField: (field) => setState(() {
              if (!_fields.add(field)) _fields.remove(field);
            }),
            onMood: (mood) =>
                setState(() => _mood = _mood == mood ? null : mood),
            onBack: () => _go(3),
            onNext: () => _go(5),
          ),
          _Reminder(
            busy: _busy,
            onBack: () => _go(4),
            onAllow: () => _finish(reminder: true),
            onSkip: () => _finish(reminder: false),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(28, top + 32, 28, bottom + 24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'Short lines and speeches, with the source still attached.',
            textAlign: TextAlign.center,
            style: serif(palette, 34, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            kAppName,
            textAlign: TextAlign.center,
            style: sans(palette, 16, color: palette.textMuted),
          ),
          const Spacer(),
          PrimaryButton(label: 'Get started', onPressed: onStart),
        ],
      ),
    );
  }
}

class _ValuePage extends StatelessWidget {
  const _ValuePage({
    required this.art,
    required this.title,
    required this.body,
    required this.showSkip,
    required this.onNext,
    required this.onSkip,
    required this.page,
  });

  final Widget art;
  final String title;
  final String body;
  final bool showSkip;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int page;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: showSkip
                ? Pressable(
                    onPressed: onSkip,
                    semanticLabel: 'Skip',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Skip',
                        style: sans(
                          palette,
                          15,
                          weight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(height: 32),
          ),
          const Spacer(),
          Center(child: art),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: serif(palette, 32, height: 1.15),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: sans(palette, 16, height: 1.4, color: palette.textMuted),
          ),
          const Spacer(),
          Row(
            children: [
              for (var dot = 0; dot < 3; dot++)
                AnimatedContainer(
                  duration: reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  width: dot == page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dot == page ? palette.accent : palette.textFaint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _ValueArt extends StatelessWidget {
  const _ValueArt({required this.index, required this.animation});

  final int index;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final lift = reduceMotion(context) ? 0.0 : (animation.value - 0.5) * 8;
        return Transform.translate(
          offset: Offset(0, lift),
          child: Container(
            width: 200,
            height: 240,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: palette.text, width: 3),
              boxShadow: [
                BoxShadow(
                  color: palette.backdrop.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.cardAlt,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    index == 0
                        ? 'One line'
                        : index == 1
                        ? 'Go deeper'
                        : 'A daily line',
                    style: serif(palette, 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    index == 0
                        ? 'Long enough to read. Short enough to keep.'
                        : index == 1
                        ? 'Context and the source stay on the card.'
                        : 'A streak counts a day you open a line.',
                    textAlign: TextAlign.center,
                    style: sans(palette, 12, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Personalize extends StatelessWidget {
  const _Personalize({
    required this.fields,
    required this.mood,
    required this.onField,
    required this.onMood,
    required this.onBack,
    required this.onNext,
  });

  final Set<Field> fields;
  final Mood? mood;
  final ValueChanged<Field> onField;
  final ValueChanged<Mood> onMood;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Pressable(
            onPressed: onBack,
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
        ),
        const SizedBox(height: 24),
        Text('Make it yours', style: serif(palette, 34, height: 1.1)),
        const SizedBox(height: 8),
        Text(
          'Follow the fields you want first, and the mood you usually arrive with.',
          style: sans(palette, 16, height: 1.4, color: palette.textMuted),
        ),
        const SizedBox(height: 24),
        Text(
          'Fields',
          style: sans(
            palette,
            13,
            weight: FontWeight.w600,
            color: palette.textFaint,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final field in collectionFields)
              ChoiceChipButton(
                label: fieldInfo[field]!.title,
                selected: fields.contains(field),
                onTap: () => onField(field),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Usual mood',
          style: sans(
            palette,
            13,
            weight: FontWeight.w600,
            color: palette.textFaint,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in Mood.values)
              ChoiceChipButton(
                label: entry.label,
                selected: mood == entry,
                onTap: () => onMood(entry),
              ),
          ],
        ),
        const SizedBox(height: 32),
        PrimaryButton(label: 'Continue', onPressed: onNext),
      ],
    );
  }
}

class _Reminder extends StatelessWidget {
  const _Reminder({
    required this.busy,
    required this.onBack,
    required this.onAllow,
    required this.onSkip,
  });

  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Spacer(),
          Text('8:00', style: serif(palette, 64, height: 1)),
          const SizedBox(height: 16),
          Text('A nudge at eight', style: serif(palette, 32, height: 1.1)),
          const SizedBox(height: 8),
          Text(
            'One local reminder. It stays on this phone, and you can turn it off later.',
            style: sans(palette, 16, height: 1.4, color: palette.textMuted),
          ),
          const Spacer(),
          PrimaryButton(
            label: busy ? 'One moment' : 'Allow',
            onPressed: busy ? () {} : onAllow,
          ),
          const SizedBox(height: 8),
          OutlineButton(label: 'Not now', onPressed: busy ? () {} : onSkip),
        ],
      ),
    );
  }
}
