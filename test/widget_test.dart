import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moti_scroll/data/models.dart';
import 'package:moti_scroll/main.dart';
import 'package:moti_scroll/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run opens onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MotiApp(state: state));
    await tester.pump();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Moti Scroll'), findsWidgets);
  });

  testWidgets('onboarding finishes on Home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(MotiApp(state: state));
    await tester.pump();

    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Scroll with purpose'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Make it yours'), findsOneWidget);

    await tester.ensureVisible(find.text('Leadership'));
    await tester.tap(find.text('Leadership'));
    await tester.ensureVisible(find.text('Need focus'));
    await tester.tap(find.text('Need focus'));
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
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
}
