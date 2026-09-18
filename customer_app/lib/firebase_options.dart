// File generated manually based on Firebase CLI config.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCFCAQmMXgIGIY9-8LYtMPpKzke6XJJqt8',
    appId: '1:195944372045:web:e3ac2ce608926126044904',
    messagingSenderId: '195944372045',
    projectId: 'protech-cs-app-alert-test',
    authDomain: 'protech-cs-app-alert-test.firebaseapp.com',
    storageBucket: 'protech-cs-app-alert-test.firebasestorage.app',
    measurementId: 'G-X3HFNDLNXD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX_aGpSbweKDlBApzlx5baRLnN7KdFVpk',
    appId: '1:195944372045:android:304d8942b7ec76b9044904',
    messagingSenderId: '195944372045',
    projectId: 'protech-cs-app-alert-test',
    storageBucket: 'protech-cs-app-alert-test.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDX_aGpSbweKDlBApzlx5baRLnN7KdFVpk',
    appId: '1:195944372045:ios:a229f8669e1579c1044904',
    messagingSenderId: '195944372045',
    projectId: 'protech-cs-app-alert-test',
    storageBucket: 'protech-cs-app-alert-test.firebasestorage.app',
    iosBundleId: 'com.example.customerApp',
  );

  static const FirebaseOptions macos = ios;
}
