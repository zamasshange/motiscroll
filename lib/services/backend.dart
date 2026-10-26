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

const useFirebase = bool.fromEnvironment('USE_FIREBASE');
const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: true);

/// Connects the existing [AppState] to Firebase when the app is launched with
/// `--dart-define=USE_FIREBASE=true`. A failed init leaves the on-phone catalog
/// in place. Analytics is not started.
Future<void> attachBackend(AppState state) async {
  if (!useFirebase) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (useEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestProvider(),
      );
    } on Exception {
      // App Check needs a registered iOS or Android app. Emulators do not enforce it.
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
      });
      await config.fetchAndActivate();
    } on Exception {
      // Remote Config is optional. Flags also live in config/flags.
    }
    await FirebaseAuth.instance.signInAnonymously();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    state.remote = true;
    state.repository = FirestoreItemRepository(FirebaseFirestore.instance);
    state.directory = FirestoreUserDirectory(FirebaseFirestore.instance, uid);
    state.accountLabel = 'Saved on this device';
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
  } on Exception {
    state.catalogError = 'The library could not be opened. Lines saved on this phone are still here.';
    state.remote = false;
  }
}

Future<void> linkGoogle(AppState state) => _link(state, GoogleAuthProvider());

Future<void> linkApple(AppState state) =>
    _link(state, OAuthProvider('apple.com'));

Future<void> sendEmailLink(String email) {
  return FirebaseAuth.instance.sendSignInLinkToEmail(
    email: email,
    actionCodeSettings: ActionCodeSettings(
      url: 'https://motiscroll.firebaseapp.com/finishSignIn',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.motiScroll',
      androidPackageName: 'com.example.moti_scroll',
      androidInstallApp: true,
    ),
  );
}

Future<void> _link(AppState state, AuthProvider provider) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    await FirebaseAuth.instance.signInWithProvider(provider);
  } else if (user.isAnonymous) {
    await user.linkWithProvider(provider);
  } else {
    await FirebaseAuth.instance.signInWithProvider(provider);
  }
  state.accountLabel = FirebaseAuth.instance.currentUser?.email ?? 'Signed in';
  state.notifyAccount();
}

Future<void> signOutToAnonymous(AppState state) async {
  await FirebaseAuth.instance.signOut();
  await FirebaseAuth.instance.signInAnonymously();
  state.accountLabel = 'Saved on this device';
  state.notifyAccount();
}

Future<void> deleteAccount() async {
  await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
}
