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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  var _seeded = false;
  var _busy = false;
  final _fields = <Field>{};
  Mood? _mood;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final state = AppScope.of(context);
    _fields.addAll(state.followed);
    _mood = state.usualMood;
    _seeded = true;
  }

  @override
  void dispose() {
    _page.dispose();
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
        children: [
          _Welcome(onStart: () => _go(1)),
          _ValuePage(
            image: 'assets/onboarding/home.png',
            title: 'A line is waiting',
            body:
                'Home opens on the line of the day, a finder, and today\'s line.',
            showSkip: true,
            onNext: () => _go(2),
            onSkip: () => _go(4),
            page: 0,
          ),
          _ValuePage(
            image: 'assets/onboarding/discover.png',
            title: 'Go deeper on any quote',
            body:
                'Context, a fact, and a next step sit behind the line. The source stays in view.',
            showSkip: true,
            onNext: () => _go(3),
            onSkip: () => _go(4),
            page: 1,
          ),
          _ValuePage(
            image: 'assets/onboarding/feed.png',
            title: 'Scroll with purpose',
            body:
                'One passage at a time, long enough to read and short enough to keep.',
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
          _WidgetOffer(onNext: () => _go(6), onBack: () => _go(4)),
          _Reminder(
            busy: _busy,
            onBack: () => _go(5),
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
            style: serif(palette, 36, height: 1.15),
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
    required this.image,
    required this.title,
    required this.body,
    required this.showSkip,
    required this.onNext,
    required this.onSkip,
    required this.page,
  });

  final String image;
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
      padding: EdgeInsets.fromLTRB(24, top + 4, 24, bottom + 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: showSkip
                ? Pressable(
                    onPressed: onSkip,
                    semanticLabel: 'Skip',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                : const SizedBox(height: 28),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: serif(palette, 36, height: 1.12),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: sans(palette, 17, height: 1.35, color: palette.textMuted),
          ),
          const SizedBox(height: 18),
          Expanded(child: _PhoneFrame(image: image)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var dot = 0; dot < 3; dot++)
                AnimatedContainer(
                  duration: reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  width: dot == page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: dot == page ? palette.accent : palette.textFaint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const shot = 1206 / 2622;
        const bezelFrac = 0.042;
        final outerAspect = (1 + 2 * bezelFrac) / (1 / shot + 2 * bezelFrac);
        var outerW = constraints.maxWidth;
        var outerH = outerW / outerAspect;
        if (outerH > constraints.maxHeight) {
          outerH = constraints.maxHeight;
          outerW = outerH * outerAspect;
        }
        final bezel = outerW * bezelFrac / (1 + 2 * bezelFrac);
        final radius = (outerW - bezel * 2) * 0.125;
        return Center(
          child: Container(
            width: outerW,
            height: outerH,
            padding: EdgeInsets.all(bezel),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(radius + bezel),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x331C1610),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
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

class _WidgetOffer extends StatelessWidget {
  const _WidgetOffer({required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

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
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B0D),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your daily quote appears here',
                    style: serif(palette, 22, color: const Color(0xFFF4F1EA)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sample',
                    style: sans(palette, 13, color: const Color(0xFFE07A4A)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Add a widget', style: serif(palette, 32, height: 1.1)),
          const SizedBox(height: 8),
          Text(
            'A line can sit on the home screen. You can add it later from Settings.',
            style: sans(palette, 16, height: 1.4, color: palette.textMuted),
          ),
          const Spacer(),
          OutlineButton(label: 'Maybe later', onPressed: onNext),
        ],
      ),
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
