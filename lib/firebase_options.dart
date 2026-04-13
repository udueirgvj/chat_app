// lib/firebase_options.dart
// ══════════════════════════════════════════════════════════════════════════════
//  ⚠️  هذا الملف يجب توليده تلقائياً باستخدام FlutterFire CLI
//  لا تكتب هذا الملف يدوياً — اتبع الخطوات التالية:
//
//  1. ثبّت FlutterFire CLI:
//     dart pub global activate flutterfire_cli
//
//  2. في مجلد المشروع:
//     flutterfire configure
//
//  3. اختر مشروع Firebase → سيُنشئ هذا الملف تلقائياً
// ══════════════════════════════════════════════════════════════════════════════

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not supported for this platform.',
        );
    }
  }

  // ─── استبدل هذه القيم بقيمك الحقيقية من Firebase Console ───────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  );
}
