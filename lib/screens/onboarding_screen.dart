import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/languages.dart';
import '../notifications/notification_prefs.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/chrome.dart';
import 'notification_offer.dart';
import 'onboarding_previews.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  var _seeded = false;
  var _busy = false;
  String? _language;
  final _fields = <Field>{};
  Mood? _mood;
  var _notifyPrefs = const NotificationPrefs();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final state = AppScope.of(context);
    final device = View.of(context).platformDispatcher.locale;
    _language = state.contentLanguage ?? state.resolvedContentLanguage(device);
    _fields.addAll(state.followed);
    _mood = state.usualMood;
    _notifyPrefs = state.notificationPrefs;
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

  Future<void> _finish({required bool enable}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppScope.of(context);
    state.setNotificationPrefs(_notifyPrefs);
    if (enable) {
      try {
        await state.enableNotifications().timeout(const Duration(seconds: 12));
      } on Object {
        // Permission or scheduling can stall after Allow. Leave onboarding.
      }
    } else {
      state.dismissNotificationAsk();
    }
    if (!mounted) return;
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
          _LanguagePage(
            selected: _language,
            onSelect: (code) => setState(() => _language = code),
            onBack: () => _go(0),
            onNext: () {
              AppScope.of(context).setContentLanguage(_language);
              _go(2);
            },
          ),
          _TopicsPage(
            fields: _fields,
            mood: _mood,
            onField: (field) => setState(() {
              if (!_fields.add(field)) _fields.remove(field);
            }),
            onAllFields: () => setState(() {
              if (_fields.length == collectionFields.length) {
                _fields.clear();
              } else {
                _fields
                  ..clear()
                  ..addAll(collectionFields);
              }
            }),
            onMood: (mood) =>
                setState(() => _mood = _mood == mood ? null : mood),
            onBack: () => _go(1),
            onNext: () => _go(3),
          ),
          _ValuePage(
            title: 'A line is waiting',
            body:
                'Home opens on the line of the day, a finder, and today\'s line.',
            preview: const OnboardHomePreview(),
            showSkip: true,
            onNext: () => _go(4),
            onSkip: () => _go(6),
            page: 0,
          ),
          _ValuePage(
            title: 'Go deeper on any quote',
            body:
                'Context, a fact, and a next step sit behind the line. The source stays in view.',
            preview: const OnboardStudyPreview(),
            showSkip: true,
            onNext: () => _go(5),
            onSkip: () => _go(6),
            page: 1,
          ),
          _ValuePage(
            title: 'Scroll with purpose',
            body:
                'One passage at a time, long enough to read and short enough to keep.',
            preview: const OnboardFeedPreview(),
            showSkip: true,
            onNext: () => _go(6),
            onSkip: () => _go(6),
            page: 2,
          ),
          _WidgetOffer(onNext: () => _go(7), onBack: () => _go(5)),
          NotificationOffer(
            busy: _busy,
            prefs: _notifyPrefs,
            onPrefs: (prefs) => setState(() => _notifyPrefs = prefs),
            onBack: () => _go(6),
            onTurnOn: () => _finish(enable: true),
            onSkip: () => _finish(enable: false),
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
      padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
      child: Column(
        children: [
          const MotiMark(size: 44),
          const SizedBox(height: 20),
          Text(
            'Short lines and speeches, with the source still attached.',
            textAlign: TextAlign.center,
            style: serif(palette, 32, height: 1.12),
          ),
          const SizedBox(height: 8),
          Text(
            kAppName,
            textAlign: TextAlign.center,
            style: sans(palette, 15, color: palette.textMuted),
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: OnboardDeviceFrame(child: OnboardHomePreview()),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Get started', onPressed: onStart),
        ],
      ),
    );
  }
}

class _ValuePage extends StatelessWidget {
  const _ValuePage({
    required this.preview,
    required this.title,
    required this.body,
    required this.showSkip,
    required this.onNext,
    required this.onSkip,
    required this.page,
  });

  final Widget preview;
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
          Expanded(child: OnboardDeviceFrame(child: preview)),
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

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final device = View.of(context).platformDispatcher.locale;
    final languages = languagesForPicker(device);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, bottom + 16),
      child: Column(
        children: [
          _OnboardBar(onBack: onBack, title: 'Select language'),
          const SizedBox(height: 12),
          Text(
            'You can change this later. Labels follow this language. The lines stay in the speaker’s words.',
            textAlign: TextAlign.center,
            style: sans(palette, 14, height: 1.4, color: palette.textMuted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: languages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.15,
              ),
              itemBuilder: (context, index) {
                final language = languages[index];
                final on = selected == language.code;
                return Pressable(
                  onPressed: () => onSelect(language.code),
                  semanticLabel: language.nativeName,
                  child: AnimatedContainer(
                    duration: reduceMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: on ? palette.accent : palette.border,
                        width: on ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: palette.cardAlt,
                          child: Text(
                            language.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                language.nativeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sans(
                                  palette,
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                language.code.toUpperCase(),
                                style: sans(
                                  palette,
                                  11,
                                  color: palette.textFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (on)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: palette.accent,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('onboard-language-continue'),
            label: 'Continue',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _TopicsPage extends StatelessWidget {
  const _TopicsPage({
    required this.fields,
    required this.mood,
    required this.onField,
    required this.onAllFields,
    required this.onMood,
    required this.onBack,
    required this.onNext,
  });

  final Set<Field> fields;
  final Mood? mood;
  final ValueChanged<Field> onField;
  final VoidCallback onAllFields;
  final ValueChanged<Mood> onMood;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final allFields = fields.length == collectionFields.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, bottom + 16),
      child: Column(
        children: [
          _OnboardBar(
            onBack: onBack,
            title: 'Select topics',
            trailing: Pressable(
              onPressed: onNext,
              semanticLabel: 'Skip',
              child: Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  'Skip',
                  style: sans(palette, 15, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can change this later. Follow a field and Feed and Discover stay on it.',
            textAlign: TextAlign.center,
            style: sans(palette, 14, height: 1.4, color: palette.textMuted),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _TopicGroup(
                  icon: Icons.grid_view_rounded,
                  title: 'Fields',
                  allSelected: allFields,
                  onAll: onAllFields,
                  children: [
                    for (final field in collectionFields)
                      ChoiceChipButton(
                        label: fieldInfo[field]!.title,
                        selected: fields.contains(field),
                        onTap: () => onField(field),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _TopicGroup(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Usual mood',
                  children: [
                    for (final entry in Mood.values)
                      ChoiceChipButton(
                        label: entry.label,
                        selected: mood == entry,
                        onTap: () => onMood(entry),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('onboard-topics-continue'),
            label: 'Continue',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _TopicGroup extends StatelessWidget {
  const _TopicGroup({
    required this.icon,
    required this.title,
    required this.children,
    this.allSelected = false,
    this.onAll,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool allSelected;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.text),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: sans(palette, 16, weight: FontWeight.w700),
                ),
              ),
              if (onAll != null)
                Pressable(
                  onPressed: onAll,
                  semanticLabel: 'All $title',
                  child: Text(
                    'All',
                    style: sans(
                      palette,
                      14,
                      weight: FontWeight.w600,
                      color: allSelected ? palette.accent : palette.textFaint,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _OnboardBar extends StatelessWidget {
  const _OnboardBar({
    required this.onBack,
    required this.title,
    this.trailing,
  });

  final VoidCallback onBack;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).palette;
    return Row(
      children: [
        Pressable(
          onPressed: onBack,
          semanticLabel: 'Back',
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Icon(Icons.chevron_left_rounded, color: palette.text),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: sans(palette, 17, weight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: trailing == null ? 40 : null,
          child: trailing ?? const SizedBox(width: 40),
        ),
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
          const OnboardWidgetPreview(),
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

