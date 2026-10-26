import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client config from the Firebase console (project `motiscroll`).
///
/// This is the web app the console generated. It is not a server secret:
/// Firestore rules, App Check, and Auth providers are what protect the data.
/// Register the iOS and Android apps in the console and replace the mobile
/// app ids with `flutterfire configure` before a store build. Analytics is
/// intentionally not started.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2lrKzbD1H7H-6ZOPDjT_VURw6z6kJpKM',
    appId: '1:618992651998:web:b8f1fcc4b16f8bdaf87c4f',
    messagingSenderId: '618992651998',
    projectId: 'motiscroll',
    authDomain: 'motiscroll.firebaseapp.com',
    storageBucket: 'motiscroll.firebasestorage.app',
    measurementId: 'G-FRHCZTJ64R',
  );

  /// Same project until an Android app is registered. `flutterfire configure`
  /// should replace `appId` with the `:android:` id.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2lrKzbD1H7H-6ZOPDjT_VURw6z6kJpKM',
    appId: '1:618992651998:web:b8f1fcc4b16f8bdaf87c4f',
    messagingSenderId: '618992651998',
    projectId: 'motiscroll',
    storageBucket: 'motiscroll.firebasestorage.app',
  );

  /// Same project until an iOS app is registered. `flutterfire configure`
  /// should replace `appId` with the `:ios:` id and add GoogleService-Info.plist.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA2lrKzbD1H7H-6ZOPDjT_VURw6z6kJpKM',
    appId: '1:618992651998:web:b8f1fcc4b16f8bdaf87c4f',
    messagingSenderId: '618992651998',
    projectId: 'motiscroll',
    storageBucket: 'motiscroll.firebasestorage.app',
    iosBundleId: 'com.example.motiScroll',
  );
}
