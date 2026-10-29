import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/main.dart';
import 'package:moti_scroll/screens/feed_screen.dart';
import 'package:moti_scroll/state/app_state.dart';

import 'support/ui_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run opens onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MotiApp(state: state));
    await tester.pump();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('MotiScroll'), findsWidgets);
  });

  testWidgets('onboarding finishes on Home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.debugSeed(uiFixture());
    await tester.pumpWidget(MotiApp(state: state));
    await tester.pump();

    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Select language'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboard-language-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Select topics'), findsOneWidget);

    await tester.ensureVisible(find.text('Leadership'));
    await tester.tap(find.text('Leadership'));
    await tester.ensureVisible(find.text('Need focus'));
    await tester.tap(find.text('Need focus'));
    await tester.tap(find.byKey(const Key('onboard-topics-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('A line is waiting'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Maybe later'), findsOneWidget);
    await tester.tap(find.text('Maybe later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LINE OF THE DAY'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("Today's speech"),
      400,
      scrollable: find.descendant(
        of: find.byKey(const Key('home-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text("Today's speech"), findsOneWidget);
    expect(state.followed.contains(Field.leadership), isTrue);
    expect(state.usualMood, Mood.needFocus);

    await tester.tap(find.text('Collections'));
    await tester.pump();
    expect(find.text('Sports'), findsOneWidget);
    expect(find.text('Follow'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('feed shows quotes and skips sourcing placeholders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    const person = AuthorProfile(
      id: 'roster-person',
      name: 'Roster Person',
      role: 'Test role',
      field: Field.sports,
      bornYear: 1960,
      isLiving: true,
    );
    state.debugSeed(uiFixture(), profiles: const [person]);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: Scaffold(body: FeedScreen())),
      ),
    );
    await tester.pump();

    final shown =
        find.text('A fixture line for the home screen test.').evaluate().isNotEmpty ||
        find
            .text('A fixture speech line for the home screen test.')
            .evaluate()
            .isNotEmpty;
    expect(shown, isTrue);
    expect(find.text('Verified quotes are being sourced'), findsNothing);
    expect(find.text('Roster Person'), findsNothing);
  });

  testWidgets('searching and choosing a person keeps the feed responsive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    state.debugSeed([
      ...uiFixture(),
      Item(
        id: 'other-person',
        type: 'quote',
        text: 'A second person line.',
        author: 'Ada Lovelace',
        authorRole: 'Test',
        field: Field.science,
        moods: const [],
        source: const Source(title: 'Notes'),
        verified: true,
        deeper: const Deeper(
          context: 'Context',
          didYouKnow: 'Note',
          takeaway: '',
          related: [],
        ),
      ),
    ]);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: FeedScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Select person'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'ada');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Ada Lovelace'));
    await tester.pumpAndSettle();

    expect(find.text('Select person'), findsNothing);
    expect(find.text('A second person line.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Like').first);
    await tester.pump();
    expect(state.liked, contains('other-person'));
  });
}
