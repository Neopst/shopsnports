import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import '../utils/app_logger.dart';

class FirebaseService {
  static bool _initialized = false;

  // Initialize Firebase with offline persistence
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable offline persistence
      await _enableOfflinePersistence();

      _initialized = true;
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      AppLogger.error('Firebase initialization failed: $e');
      rethrow;
    }
  }

  // Enable Firestore offline persistence
  static Future<void> _enableOfflinePersistence() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Enable persistence with cache size
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      AppLogger.info('Firestore offline persistence enabled');
    } catch (e) {
      AppLogger.error('Failed to enable offline persistence: $e');
    }
  }

  // Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}
