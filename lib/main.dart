import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'l10n/languages.dart';
import 'notifications/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'services/backend.dart';
import 'share/quote_card_renderer.dart';
import 'shell.dart';
import 'state/app_state.dart';
import 'theme/tokens.dart';
import 'widgets/widget_payload.dart';
import 'widgets/widget_sync.dart';

var _previewExtensionRegistered = false;

void registerPreviewNotifyExtension(AppState state) {
  if (_previewExtensionRegistered) return;
  _previewExtensionRegistered = true;
  developer.registerExtension('ext.motiscroll.previewNotify', (
    method,
    params,
  ) async {
    try {
      final shown = await state.previewNotifications();
      return developer.ServiceExtensionResponse.result('{"shown":$shown}');
    } on Object catch (error) {
      return developer.ServiceExtensionResponse.error(1, '$error');
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  if (useFirebase) {
    state.catalogLoading = true;
  }
  if (!kReleaseMode) {
    registerPreviewNotifyExtension(state);
  }
  runApp(MotiApp(state: state));
  unawaited(_startServices(state));
}

Future<void> _startServices(AppState state) async {
  unawaited(QuoteCardRenderer.cleanupTemp());
  unawaited(WidgetSyncService.registerRefresh());
  await attachBackend(state);
}

class MotiApp extends StatefulWidget {
  const MotiApp({super.key, required this.state});

  final AppState state;

  @override
  State<MotiApp> createState() => _MotiAppState();
}

class _MotiAppState extends State<MotiApp> with WidgetsBindingObserver {
  late bool _dark = widget.state.dark;
  late bool _largeText = widget.state.largeText;
  late String? _language =
      widget.state.uiLanguage ?? widget.state.contentLanguage;
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_onState);
    _syncSystemBrightness();
    _applyOverlay();
    _listenForWidgetLinks();
    _listenForNotifications();
    registerPreviewNotifyExtension(widget.state);
    _maybePreviewNotifications();
  }

  void _maybePreviewNotifications() {
    if (kReleaseMode) return;
    if (!const bool.fromEnvironment('PREVIEW_NOTIFY')) return;
    unawaited(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await widget.state.previewNotifications();
    }());
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_onState);
    super.dispose();
  }

  Future<void> _listenForWidgetLinks() async {
    try {
      await HomeWidget.setAppGroupId(widgetAppGroup);
      final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (!mounted) return;
      widget.state.openWidgetLink(initial);
      _widgetClicks = HomeWidget.widgetClicked.listen(
        widget.state.openWidgetLink,
        onError: (_) {},
      );
    } on Object {
      return;
    }
  }

  Future<void> _listenForNotifications() async {
    final service = NotificationService.instance;
    service.onTap = (payload) {
      widget.state.openWidgetLink(notificationPayloadUri(payload));
    };
    try {
      await service.initialize();
      final launch = await service.launchPayload();
      if (!mounted) return;
      if (launch != null) {
        widget.state.openWidgetLink(notificationPayloadUri(launch));
      }
      await widget.state.syncNotifications();
    } on Object {
      return;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.state.syncNotifications());
    }
  }

  @override
  void didChangePlatformBrightness() => _syncSystemBrightness();

  void _syncSystemBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    widget.state.applySystemBrightness(brightness == Brightness.dark);
  }

  void _onState() {
    final state = widget.state;
    if (state.followSystemTheme) _syncSystemBrightness();
    final language = state.uiLanguage ?? state.contentLanguage;
    if (state.dark == _dark &&
        state.largeText == _largeText &&
        language == _language) {
      return;
    }
    setState(() {
      _dark = state.dark;
      _largeText = state.largeText;
      _language = language;
    });
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
        builder: (context, child) {
          final state = AppScope.of(context);
          final code =
              state.uiLanguage ??
              state.resolvedContentLanguage(
                View.of(context).platformDispatcher.locale,
              );
          final direction =
              languageByCode(code)?.direction ?? TextDirection.ltr;
          Widget body = child ?? const SizedBox.shrink();
          if (_largeText) {
            final media = MediaQuery.of(context);
            body = MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  (media.textScaler.scale(1) * 1.15).clamp(1.0, 2.0),
                ),
              ),
              child: body,
            );
          }
          return Directionality(textDirection: direction, child: body);
        },
        home: const _Gate(),
      ),
    );
  }
}

const _libraryRevision = 14;
var _appliedLibraryRevision = 0;

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (_appliedLibraryRevision != _libraryRevision &&
        (state.repository != null || state.catalogError != null)) {
      _appliedLibraryRevision = _libraryRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.repository == null) {
          attachBackend(state);
        } else {
          state.refreshCatalog();
        }
      });
    }
    final onboarded = state.onboardingComplete;
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
    ).copyWith(surfaceTint: const Color(0x00000000)),
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.sheet,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      modalElevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
      ),
    ),
  );
}
