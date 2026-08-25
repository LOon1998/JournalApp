// GENERATED-STYLE FILE — but hand-written with placeholders, not actually
// generated yet. This is normally produced by running `flutterfire configure`
// (from the FlutterFire CLI) against a real Firebase project, which asks you
// to log in and pick/create a project, then writes real values here for you.
//
// Since that requires your own Google account and a Firebase project that
// doesn't exist yet, here's the manual path instead — same end result:
//
//   1. Go to https://console.firebase.google.com, create a new project
//      (e.g. "Moodlet").
//   2. In that project, click "Add app" → Web (</> icon). Register it
//      (nickname doesn't matter) — Firebase shows you a config object with
//      apiKey, authDomain, projectId, etc. Copy those into `web` below.
//   3. Click "Add app" → Android. Use package name `com.lumina.lumina`
//      (matches android/app/build.gradle.kts already in this project).
//      You can skip downloading `google-services.json` — this project
//      doesn't use the Gradle google-services plugin, since passing
//      FirebaseOptions here in Dart is all firebase_core/auth/firestore
//      actually need. Firebase still shows you the same apiKey/appId/etc.
//      values right on the registration screen (and again any time under
//      Project settings → your apps) — copy those into `android` below
//      (its appId is the Android one, different from the web appId).
//   4. In the Firebase console, go to Authentication → Sign-in method →
//      enable "Email/Password".
//   5. Go to Firestore Database → Create database → start in production
//      mode → pick a region. Then go to the Rules tab and paste in the
//      contents of firestore.rules (added alongside this file) — that's
//      what actually keeps one person's journal private from everyone
//      else's.
//
// None of the values below are secret in the way an API key normally is —
// Firebase's web/Android config identifies which project to talk to, but
// doesn't grant access to anything by itself; the Firestore rules above
// are what actually enforce privacy. So this file is safe to commit as-is.
//
// Both `web` and `android` below are filled in with this project's real
// values (project "website-1551755601970" / package com.lumina.lumina).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have only been configured for web and Android in this project.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBXYcck9WlUvRoncEOiGwtQHikerJainkU',
    appId: '1:779650679650:web:f387f486c5759a6cf6623b',
    messagingSenderId: '779650679650',
    projectId: 'website-1551755601970',
    authDomain: 'website-1551755601970.firebaseapp.com',
    storageBucket: 'website-1551755601970.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCVBMqwr4J9l_ABgOg1IvgpFZrtzMkoKhQ',
    appId: '1:779650679650:android:5b91d17cbcef6656f6623b',
    messagingSenderId: '779650679650',
    projectId: 'website-1551755601970',
    storageBucket: 'website-1551755601970.firebasestorage.app',
  );
}
