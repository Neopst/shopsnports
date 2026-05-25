import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'core/firebase/firebase_options.dart';
import 'core/utils/app_logger.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.firebase('Background notification: ${message.notification?.title}');
}

void main() {
  runApp(const ProviderScope(child: AppInitializer()));
}

/// App Initializer - Handles Firebase initialization before showing the app
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      AppLogger.firebase('Firebase initialized successfully');
      AppLogger.firebase('Storage bucket: ${Firebase.app().options.storageBucket}');

      _setupFirebaseMessaging();
    } catch (e) {
      AppLogger.error('Firebase initialization error: $e', tag: 'Init');
    }
  }

  void _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.firebase('Push notification permission granted');

        try {
          final token = await messaging.getToken(
            vapidKey:
                'BOd3HTz3buyuOgxJ04L45fveO2Va8eRvTbAMvuVdzh95pzkyZK0eqSejuKbu_7UY3ZNKTm5FmHb6YTRASZqJoqg',
          );
          if (token != null) {
            AppLogger.firebase('FCM Token received', tag: 'FCM');
          }
        } catch (e) {
          AppLogger.warning('FCM token error (safe to ignore on web): $e', tag: 'FCM');
        }
      }
    } catch (e) {
      AppLogger.warning('Firebase Messaging setup error (continuing anyway): $e', tag: 'FCM');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // Show loading screen while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Initializing Admin Dashboard...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show error screen if initialization failed
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Failed to initialize app',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initialization = _initializeApp();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Firebase initialized successfully - show the app
        AppLogger.info('App ready - showing login screen');
        return const MyApp();
      },
    );
  }
}
