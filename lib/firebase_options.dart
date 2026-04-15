
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyADoE6-IP6u-05xLh0A1kK0TwA3UgBR1pc',
    appId: '1:105536290789:web:a5e22add4b357e7319b90c',
    messagingSenderId: '105536290789',
    projectId: 'ashesilife',
    authDomain: 'ashesilife.firebaseapp.com',
    storageBucket: 'ashesilife.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD2ns3oE6x3W4454ANTJVdwpFyP85ElbQw',
    appId: '1:105536290789:ios:0ad457ca32517a8119b90c',
    messagingSenderId: '105536290789',
    projectId: 'ashesilife',
    storageBucket: 'ashesilife.firebasestorage.app',
    iosBundleId: 'com.example.ashesilife',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyADoE6-IP6u-05xLh0A1kK0TwA3UgBR1pc',
    appId: '1:105536290789:web:c7d725e1dad83ec019b90c',
    messagingSenderId: '105536290789',
    projectId: 'ashesilife',
    authDomain: 'ashesilife.firebaseapp.com',
    storageBucket: 'ashesilife.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2ns3oE6x3W4454ANTJVdwpFyP85ElbQw',
    appId: '1:105536290789:ios:0ad457ca32517a8119b90c',
    messagingSenderId: '105536290789',
    projectId: 'ashesilife',
    storageBucket: 'ashesilife.firebasestorage.app',
    iosBundleId: 'com.example.ashesilife',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATzxR7mlAB7fqV0kSM96-ANu5I9ytYT88',
    appId: '1:105536290789:android:5c6fd8cbaf9d2b4119b90c',
    messagingSenderId: '105536290789',
    projectId: 'ashesilife',
    storageBucket: 'ashesilife.firebasestorage.app',
  );

}