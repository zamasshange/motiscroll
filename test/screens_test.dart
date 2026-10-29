import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moti_scroll/screens/daily_screen.dart';
import 'package:moti_scroll/screens/habit_sheet.dart';
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
    expect(find.text('Sign up or log in'), findsOneWidget);

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
