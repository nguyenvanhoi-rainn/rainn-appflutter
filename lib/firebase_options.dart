import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'rainn-app-efdf9',
    authDomain: 'rainn-app-efdf9.firebaseapp.com',
    storageBucket: 'rainn-app-efdf9.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'rainn-app-efdf9',
    storageBucket: 'rainn-app-efdf9.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'rainn-app-efdf9',
    storageBucket: 'rainn-app-efdf9.appspot.com',
    iosBundleId: 'com.example.rainnApp',
  );
}