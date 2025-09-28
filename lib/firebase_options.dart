import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBcfZoNGITsvNcnaP2TDadVAlNVIerpEaQ',
    authDomain: 'trackstatus-flutter.firebaseapp.com',
    projectId: 'trackstatus-flutter',
    storageBucket: 'trackstatus-flutter.firebasestorage.app',
    messagingSenderId: '1005522555437',
    appId: '1:1005522555437:web:64ea9120b945db8faa1ea4',
    measurementId: 'G-DB7ZL6WBPS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcfZoNGITsvNcnaP2TDadVAlNVIerpEaQ',
    appId: '1:1005522555437:android:64ea9120b945db8faa1ea4',
    messagingSenderId: '1005522555437',
    projectId: 'trackstatus-flutter',
    storageBucket: 'trackstatus-flutter.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcfZoNGITsvNcnaP2TDadVAlNVIerpEaQ',
    appId: '1:1005522555437:ios:64ea9120b945db8faa1ea4',
    databaseURL: 'https://trackstatus-flutter-default-rtdb.asia-southeast1.firebasedatabase.app',
    messagingSenderId: '1005522555437',
    projectId: 'trackstatus-flutter',
    storageBucket: 'trackstatus-flutter.firebasestorage.app',
  );
}