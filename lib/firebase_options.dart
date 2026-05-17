// File generated to match the output of `flutterfire configure`.
// Values sourced from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web. '
        'Re-run `flutterfire configure` with web enabled to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform: '
          '$defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrFRyxhrq7hks_myqN3uhbyxNGDjhwblA',
    appId: '1:70034961552:android:68693a53a111b730385415',
    messagingSenderId: '70034961552',
    projectId: 'hfn-work',
    storageBucket: 'hfn-work.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8WHLzudPQbdftVkHmjJ4KWH6Y2cRuZQY',
    appId: '1:70034961552:ios:0c460432b0b0de58385415',
    messagingSenderId: '70034961552',
    projectId: 'hfn-work',
    storageBucket: 'hfn-work.firebasestorage.app',
    iosClientId:
        '70034961552-av0f1itnf2o4ae763puv5ak096ftfp6e.apps.googleusercontent.com',
    iosBundleId: 'com.cfn.hfnWork',
  );
}