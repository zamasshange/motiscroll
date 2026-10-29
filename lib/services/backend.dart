import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../data/repositories.dart';
import '../state/app_state.dart';

const useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: true);
const useEmulator = bool.fromEnvironment('USE_EMULATOR');

class AccountException implements Exception {
  AccountException(this.message);
  final String message;
}

/// The iOS SDK aborts the process if [FirebaseOptions.appId] is a web app id.
/// That throw happens inside native code, before Dart can catch it.
bool firebaseOptionsMatchPlatform() {
  final appId = DefaultFirebaseOptions.currentPlatform.appId;
  if (kIsWeb) return appId.contains(':web:');
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => appId.contains(':ios:'),
    TargetPlatform.android => appId.contains(':android:'),
    _ => true,
  };
}

Future<void>? _attaching;

void _applyRemoteFlags(AppState state, FirebaseRemoteConfig config) {
  state.contentReady = config.getBool('contentReady');
  state.setWidgetsEnabled(config.getBool('widgetsEnabled'));
  state.applyNotificationFlags(
    enabled: config.getBool('notificationsEnabled'),
    maxPerDay: config.getInt('maxNotificationsPerDay'),
  );
}

/// Connects [AppState] to Firebase. The local catalog is not a fallback.
/// Pass `--dart-define=USE_FIREBASE=false` only for a widget test that never
/// calls this. Analytics is not started.
Future<void> attachBackend(AppState state) {
  if (!useFirebase) {
    state.accountError = 'This build is not connected to the library.';
    state.catalogLoading = false;
    state.notifyAccount();
    return Future.value();
  }
  if (state.firebaseReady && state.repository != null) {
    return Future.value();
  }
  return _attaching ??= _attachBackend(state);
}

Future<void> _attachBackend(AppState state) async {
  if (!firebaseOptionsMatchPlatform()) {
    state.accountError = 'Sign-in is off until this phone is registered in Firebase. The rest of the app still opens.';
    state.catalogLoading = false;
    state.notifyAccount();
    return;
  }
  state.catalogLoading = true;
  state.notifyAccount();
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (error) {
        // The iOS plist configures the default app before Dart runs.
        if (error.code != 'duplicate-app') rethrow;
      }
    }
    if (useEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
    }
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } on Exception {
      // A failed cache setting must not block the library read.
    }
    state.repository = FirestoreItemRepository(FirebaseFirestore.instance);
    if (state.items.isEmpty) {
      try {
        state.adoptCatalog(await state.repository!.previewOpening());
      } on Object {
        // Sign-in below retries the library read.
      }
    }
    if (kReleaseMode) {
      try {
        await FirebaseAppCheck.instance
            .activate(
              providerAndroid: const AndroidPlayIntegrityProvider(),
              providerApple: const AppleAppAttestProvider(),
            )
            .timeout(const Duration(seconds: 3));
      } on Exception {
        // A debug install has no App Attest token. Release builds still try.
      }
    }
    try {
      final record = FirebaseCrashlytics.instance.recordFlutterFatalError;
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (kReleaseMode) record(details);
        previous?.call(details);
      };
    } on Exception {
      // Crashlytics needs the native Google config. The rest of the session still runs.
    }
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: kReleaseMode
              ? const Duration(hours: 1)
              : Duration.zero,
        ),
      );
      await config.setDefaults(const {
        'charactersEnabled': false,
        'livingFiguresEnabled': true,
        'contentReady': false,
        'widgetsEnabled': true,
        'notificationsEnabled': true,
        'maxNotificationsPerDay': 2,
      });
      _applyRemoteFlags(state, config);
      unawaited(() async {
        try {
          await config.fetchAndActivate();
          _applyRemoteFlags(state, config);
          state.notifyAccount();
          await state.syncNotifications();
        } on Exception {
          // Keep the defaults already on the state.
        }
      }());
    } on Exception {
      state.contentReady = false;
    }
    state.firebaseReady = true;
    state.reloadFlags = () async {
      try {
        final config = FirebaseRemoteConfig.instance;
        await config.fetchAndActivate();
        _applyRemoteFlags(state, config);
        state.notifyAccount();
        await state.syncNotifications();
      } on Exception {
        state.contentReady = false;
      }
    };
    state.repository ??= FirestoreItemRepository(FirebaseFirestore.instance);
    final existing = FirebaseAuth.instance.currentUser;
    if (existing == null || existing.isAnonymous) {
      try {
        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: 8),
        );
      } on FirebaseAuthException catch (error) {
        state.accountError = _authMessage(error);
      } on TimeoutException {
        // A previous session can still have a user; the uid check below decides.
      }
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state.accountError ??=
          'Sign-in did not start. You can try Google from Account.';
      state.catalogLoading = false;
      state.notifyAccount();
      return;
    }
    state.remote = true;
    state.repository ??= FirestoreItemRepository(FirebaseFirestore.instance);
    state.directory = FirestoreUserDirectory(FirebaseFirestore.instance, uid);
    final signedIn = FirebaseAuth.instance.currentUser;
    if (signedIn != null && !signedIn.isAnonymous) {
      _rememberAccount(state, signedIn);
    } else {
      state.accountName = null;
      state.accountEmail = null;
      state.accountLabel = 'Saved on this device';
    }
    state.accountError = null;
    state.syncView = (itemId) async {
      final result = await FirebaseFunctions.instance
          .httpsCallable('recordView')
          .call({'itemId': itemId});
      final data = result.data;
      if (data is Map && data['streakCount'] is num) {
        return (data['streakCount'] as num).toInt();
      }
      return null;
    };
    await state.refreshCatalog();
  } on Exception catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'catalog',
        context: ErrorDescription('while starting Firebase'),
      ),
    );
    state.catalogError = libraryFailure(error);
    state.accountError = 'The account service could not be reached.';
    state.remote = false;
    state.catalogLoading = false;
    state.notifyAccount();
  }
}

Future<void> linkGoogle(AppState state) => _link(state, GoogleAuthProvider());

Future<void> signInWithEmailPassword(
  AppState state,
  String email,
  String password,
) async {
  await _ensureReady(state);
  _requireEmailPassword(email, password);
  try {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInWithCredential(credential);
    } else if (user.isAnonymous) {
      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'email-already-in-use' ||
            error.code == 'credential-already-in-use' ||
            error.code == 'account-exists-with-different-credential') {
          await FirebaseAuth.instance.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }
    } else {
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
  } on FirebaseAuthException catch (error) {
    throw AccountException(_authMessage(error));
  }
  await _afterAuth(state);
}

Future<void> createEmailAccount(
  AppState state,
  String email,
  String password,
  String name,
) async {
  await _ensureReady(state);
  final trimmed = name.trim();
  if (trimmed.length < 2) {
    throw AccountException('Enter the name for this account.');
  }
  _requireEmailPassword(email, password);
  try {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) {
      await user.linkWithCredential(credential);
    } else {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  } on FirebaseAuthException catch (error) {
    throw AccountException(_authMessage(error));
  }
  final created = FirebaseAuth.instance.currentUser;
  await created?.updateDisplayName(trimmed);
  await created?.reload();
  await _afterAuth(state);
}

Future<void> _ensureReady(AppState state) async {
  if (!state.firebaseReady) {
    await attachBackend(state);
  }
  if (!state.firebaseReady) {
    throw AccountException(
      state.accountError ?? 'The account service could not be reached.',
    );
  }
}

void _requireEmailPassword(String email, String password) {
  if (email.isEmpty || !email.contains('@')) {
    throw AccountException('Enter the email address for this account.');
  }
  if (password.length < 6) {
    throw AccountException('Use a password of at least six characters.');
  }
}

Future<void> _link(AppState state, AuthProvider provider) async {
  await _ensureReady(state);
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInWithProvider(provider);
    } else if (user.isAnonymous) {
      await user.linkWithProvider(provider);
    } else {
      await FirebaseAuth.instance.signInWithProvider(provider);
    }
  } on FirebaseAuthException catch (error) {
    throw AccountException(_authMessage(error));
  }
  await _afterAuth(state);
}

Future<void> _afterAuth(AppState state) async {
  final signedIn = FirebaseAuth.instance.currentUser;
  final uid = signedIn?.uid;
  if (uid != null) {
    state.remote = true;
    state.repository = FirestoreItemRepository(FirebaseFirestore.instance);
    state.directory = FirestoreUserDirectory(FirebaseFirestore.instance, uid);
    await state.refreshCatalog();
  }
  if (signedIn != null) _rememberAccount(state, signedIn);
  state.accountError = null;
  state.notifyAccount();
  await state.syncNotifications();
}

void _rememberAccount(AppState state, User user) {
  final name = user.displayName?.trim();
  state.accountName = name == null || name.isEmpty ? null : name;
  state.accountEmail = user.email;
  state.accountLabel = state.accountName ?? user.email ?? 'Signed in';
}

String _authMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'operation-not-allowed' =>
      'That sign-in method is turned off for this project.',
    'network-request-failed' => 'The network blocked sign-in. Try again.',
    'web-context-cancelled' ||
    'cancelled' ||
    'canceled' ||
    'popup-closed-by-user' => 'The sign-in window was closed.',
    'provider-already-linked' =>
      'That provider is already linked to this library.',
    'email-already-in-use' =>
      'That email already has an account. Sign in instead.',
    'weak-password' => 'Use a password of at least six characters.',
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' ||
    'invalid-credential' =>
      'That sign-in was not accepted. Check the details and try again.',
    'too-many-requests' => 'Too many tries. Wait a moment and try again.',
    _ => 'Sign-in could not be finished.',
  };
}

Future<void> signOutToAnonymous(AppState state) async {
  if (!state.firebaseReady) {
    throw AccountException(
      state.accountError ?? 'The account service could not be reached.',
    );
  }
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInAnonymously();
  state.accountLabel = 'Saved on this device';
  await state.clearNotifications();
  state.notifyAccount();
  await state.clearWidgets();
}

Future<void> deleteAccount() async {
  try {
    await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
  } on FirebaseFunctionsException {
    throw AccountException(
      'The account could not be deleted. Try again in a moment.',
    );
  }
}
