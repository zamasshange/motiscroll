import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onboarding_screen.dart';
import 'services/backend.dart';
import 'shell.dart';
import 'state/app_state.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  await attachBackend(state);
  runApp(MotiApp(state: state));
}

class MotiApp extends StatefulWidget {
  const MotiApp({super.key, required this.state});

  final AppState state;

  @override
  State<MotiApp> createState() => _MotiAppState();
}

class _MotiAppState extends State<MotiApp> {
  late bool _dark = widget.state.dark;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onState);
    _applyOverlay();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (widget.state.dark == _dark) return;
    setState(() => _dark = widget.state.dark);
    _applyOverlay();
  }

  void _applyOverlay() {
    final dark = widget.state.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: dark ? darkPalette.bg : lightPalette.bg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        theme: _theme(lightPalette, Brightness.light),
        darkTheme: _theme(darkPalette, Brightness.dark),
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final onboarded = AppScope.of(context).onboardingComplete;
    return onboarded ? const TabShell() : const OnboardingScreen();
  }
}

ThemeData _theme(Palette palette, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.bg,
    fontFamily: 'DMSans',
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      surface: palette.bg,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'DMSans',
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
    iconTheme: IconThemeData(color: palette.text),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      foregroundColor: palette.text,
      elevation: 0,
    ),
  );
}
