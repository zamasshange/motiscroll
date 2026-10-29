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

/// Connects [AppState] to Firebase. The local catalog is not a fallback.
/// Pass `--dart-define=USE_FIREBASE=false` only for a widget test that never
/// calls this. Analytics is not started.
Future<void> attachBackend(AppState state) async {
  if (!useFirebase) {
    state.accountError = 'This build is not connected to the library.';
    return;
  }
  if (!firebaseOptionsMatchPlatform()) {
    state.accountError = 'Sign-in is off until this phone is registered in Firebase. The rest of the app still opens.';
    return;
  }
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
    if (kReleaseMode) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleAppAttestProvider(),
        );
      } on Exception {
        // A debug install has no App Attest token. Release builds still try.
      }
    }
    try {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    } on Exception {
      // Crashlytics needs the native Google config. The rest of the session still runs.
    }
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setDefaults(const {
        'charactersEnabled': false,
        'livingFiguresEnabled': true,
        'contentReady': false,
        'widgetsEnabled': true,
      });
      await config.fetchAndActivate();
      state.contentReady = config.getBool('contentReady');
      state.setWidgetsEnabled(config.getBool('widgetsEnabled'));
    } on Exception {
      state.contentReady = false;
    }
    state.firebaseReady = true;
    state.reloadFlags = () async {
      try {
        final config = FirebaseRemoteConfig.instance;
        await config.fetchAndActivate();
        state.contentReady = config.getBool('contentReady');
        state.setWidgetsEnabled(config.getBool('widgetsEnabled'));
        state.notifyAccount();
      } on Exception {
        state.contentReady = false;
      }
    };
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      state.accountError = _authMessage(error);
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state.accountError ??=
          'Sign-in did not start. You can try Google from Account.';
      state.notifyAccount();
      return;
    }
    state.remote = true;
    state.repository = FirestoreItemRepository(FirebaseFirestore.instance);
    state.directory = FirestoreUserDirectory(FirebaseFirestore.instance, uid);
    state.accountLabel = 'Saved on this device';
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
    state.notifyAccount();
  }
}

Future<void> linkGoogle(AppState state) => _link(state, GoogleAuthProvider());

Future<void> linkApple(AppState state) =>
    _link(state, OAuthProvider('apple.com'));

Future<void> sendEmailLink(String email) async {
  if (email.isEmpty || !email.contains('@')) {
    throw AccountException(
      'Enter the email address that should receive the link.',
    );
  }
  try {
    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: 'https://motiscroll.firebaseapp.com/finishSignIn',
        handleCodeInApp: true,
        iOSBundleId: 'com.example.motiScroll',
        androidPackageName: 'com.example.moti_scroll',
        androidInstallApp: true,
      ),
    );
  } on FirebaseAuthException catch (error) {
    throw AccountException(_authMessage(error));
  }
}

Future<void> _link(AppState state, AuthProvider provider) async {
  if (!state.firebaseReady) {
    await attachBackend(state);
  }
  if (!state.firebaseReady) {
    throw AccountException(
      state.accountError ?? 'The account service could not be reached.',
    );
  }
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
  final signedIn = FirebaseAuth.instance.currentUser;
  final uid = signedIn?.uid;
  if (uid != null) {
    state.remote = true;
    state.repository = FirestoreItemRepository(FirebaseFirestore.instance);
    state.directory = FirestoreUserDirectory(FirebaseFirestore.instance, uid);
    await state.refreshCatalog();
  }
  state.accountLabel = signedIn?.email ?? 'Signed in';
  state.accountError = null;
  state.notifyAccount();
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
    'invalid-credential' => 'Google did not accept this app. The iOS or Android client is not registered yet.',
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
