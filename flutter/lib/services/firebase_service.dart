import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      debugPrint('Run "flutterfire configure" to generate firebase_options.dart');
    }
  }

  static bool get isInitialized => _initialized;
}
