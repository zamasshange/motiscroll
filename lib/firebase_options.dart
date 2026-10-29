import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client config from the Firebase console (project `motiscroll`).
///
/// These are client app ids, not server secrets. Firestore rules, App Check,
/// and Auth providers protect the data. Analytics is intentionally not started.
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNORfwJmoJ2eKQGVX3Lp0npcQFFTwpMKU',
    appId: '1:618992651998:android:1d6276bc8c7ce595f87c4f',
    messagingSenderId: '618992651998',
    projectId: 'motiscroll',
    storageBucket: 'motiscroll.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAh2FQaj3HG7NW-ZMIplvFP2VeQcpORVp8',
    appId: '1:618992651998:ios:6b12bc0734771de2f87c4f',
    messagingSenderId: '618992651998',
    projectId: 'motiscroll',
    storageBucket: 'motiscroll.firebasestorage.app',
    iosClientId: '618992651998-kmgkacqa9ihmmfaai2qrgcubgth2rvfb.apps.googleusercontent.com',
    iosBundleId: 'com.example.motiScroll',
  );
}
