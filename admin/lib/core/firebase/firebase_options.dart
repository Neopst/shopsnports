import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    if (Platform.isMacOS) {
      return macos;
    }
    if (Platform.isWindows) {
      return windows;
    }
    if (Platform.isLinux) {
      return linux;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNwSRIiKqpX6UmtF3TAZbfc77Q7GDYKls',
    appId: '1:1071327130634:web:8a9f3c7d1234567890abcdef',
    messagingSenderId: '1071327130634',
    projectId: 'shopsnports',
    authDomain: 'shopsnports.firebaseapp.com',
    storageBucket: 'shopsnports.firebasestorage.app',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNwSRIiKqpX6UmtF3TAZbfc77Q7GDYKls',
    appId: '1:1071327130634:android:abcdef1234567890',
    messagingSenderId: '1071327130634',
    projectId: 'shopsnports',
    storageBucket: 'shopsnports.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNwSRIiKqpX6UmtF3TAZbfc77Q7GDYKls',
    appId: '1:1071327130634:ios:123456abcdef',
    messagingSenderId: '1071327130634',
    projectId: 'shopsnports',
    storageBucket: 'shopsnports.firebasestorage.app',
    iosBundleId: 'com.shopsnports.admin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCNwSRIiKqpX6UmtF3TAZbfc77Q7GDYKls',
    appId: '1:1071327130634:ios:123456abcdef',
    messagingSenderId: '1071327130634',
    projectId: 'shopsnports',
    storageBucket: 'shopsnports.firebasestorage.app',
    iosBundleId: 'com.shopsnports.admin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCNwSRIiKqpX6UmtF3TAZbfc77Q7GDYKls',
    appId: '1:1071327130634:windows:abcdef123456',
    messagingSenderId: '1071327130634',
    projectId: 'shopsnports',
    authDomain: 'shopsnports.firebaseapp.com',
    storageBucket: 'shopsnports.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCNwSRIiKqpX6UmtF3TAZbfc77Q7GDYKls',
    appId: '1:1071327130634:linux:abcdef123456',
    messagingSenderId: '1071327130634',
    projectId: 'shopsnports',
    authDomain: 'shopsnports.firebaseapp.com',
    storageBucket: 'shopsnports.firebasestorage.app',
  );
}
