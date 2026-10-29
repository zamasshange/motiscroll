import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moti_scroll/screens/account_screen.dart';
import 'package:moti_scroll/screens/daily_screen.dart';
import 'package:moti_scroll/screens/habit_sheet.dart';
import 'package:moti_scroll/screens/home_screen.dart';
import 'package:moti_scroll/screens/paths_screen.dart';
import 'package:moti_scroll/screens/saved_screen.dart';
import 'package:moti_scroll/screens/settings_screen.dart';
import 'package:moti_scroll/state/app_state.dart';

import 'support/ui_fixture.dart';

Future<AppState> _pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.load();
  state.debugSeed(uiFixture());
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(home: page),
    ),
  );
  await tester.pump();
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('weeks in a row skip an empty current week', () {
    final now = DateTime(2026, 10, 28);
    expect(weeksInARow({'2026-10-20', '2026-10-13'}, now), 2);
    expect(weeksInARow({'2026-10-26', '2026-10-20'}, now), 2);
    expect(weeksInARow({'2026-10-26', '2026-10-06'}, now), 1);
    expect(weeksInARow({}, now), 0);
  });

  testWidgets('settings hub reaches general, support, and legal', (
    tester,
  ) async {
    final state = await _pumpPage(tester, const SettingsScreen());
    expect(find.text(kAppVersion), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Font size'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(state.largeText, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contact & Support'));
    await tester.pumpAndSettle();
    expect(find.text('Hi! What do you need help with?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Legal'));
    await tester.pumpAndSettle();
    expect(find.text('Photo credits'), findsOneWidget);
  });

  testWidgets('account signs in, then offers create', (tester) async {
    await _pumpPage(tester, const AccountScreen());
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Need an account? Create one'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Delete account'), findsNothing);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Email me a link'), findsNothing);

    await tester.tap(find.text('Need an account? Create one'));
    await tester.pump();
    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });

  testWidgets('notes done closes the sheet', (tester) async {
    final state = await _pumpPage(tester, const HomeScreen());
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your notes'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'come back to this');
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Done'), findsNothing);
    expect(state.notes['fixture-quote'], 'come back to this');
  });

  testWidgets('line finder hides the next field and number', (tester) async {
    await _pumpPage(tester, const HomeScreen());
    expect(find.text('Line finder'), findsOneWidget);
    expect(find.text('Leadership'), findsWidgets);
    expect(find.text('Sports'), findsNothing);
    expect(find.text('Business'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('library hub counts saved lines', (tester) async {
    final state = await _pumpPage(tester, const LibraryScreen());
    state.toggleSave('fixture-quote');
    await tester.pump();
    expect(find.text('Your library'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(
      find.text('A fixture line for the home screen test.'),
      findsOneWidget,
    );
  });

  testWidgets('paths and daily screens render from the library', (
    tester,
  ) async {
    await _pumpPage(tester, const PathsScreen());
    expect(find.text('By mood'), findsOneWidget);
    expect(find.text('Need focus'), findsWidgets);

    await _pumpPage(tester, const DailyScreen());
    expect(find.text("Start today's line"), findsOneWidget);
    expect(find.textContaining('Unlocks in'), findsOneWidget);
  });
}
