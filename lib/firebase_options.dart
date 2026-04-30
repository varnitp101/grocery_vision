

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;











class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkS1yNNKGY1H0Af8JysNYra8ZJBzZCl4E',
    appId: '1:1093584945572:android:f98ad5783306f2e02f8131',
    messagingSenderId: '1093584945572',
    projectId: 'grocery-eye',
    storageBucket: 'grocery-eye.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAoV0aDf32k9XxHbnHx9Fd0JQWi9XVM5Po',
    appId: '1:1093584945572:ios:c0b9927dc2f8c9d42f8131',
    messagingSenderId: '1093584945572',
    projectId: 'grocery-eye',
    storageBucket: 'grocery-eye.firebasestorage.app',
    iosClientId: '1093584945572-ljals11qts2g1skuurdd8th5c2586t1s.apps.googleusercontent.com',
    iosBundleId: 'com.example.groceryVision',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAoV0aDf32k9XxHbnHx9Fd0JQWi9XVM5Po',
    appId: '1:1093584945572:ios:c0b9927dc2f8c9d42f8131',
    messagingSenderId: '1093584945572',
    projectId: 'grocery-eye',
    storageBucket: 'grocery-eye.firebasestorage.app',
    iosClientId: '1093584945572-ljals11qts2g1skuurdd8th5c2586t1s.apps.googleusercontent.com',
    iosBundleId: 'com.example.groceryVision',
  );
}
