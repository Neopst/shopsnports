import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'features/auth/data/providers/auth_providers.dart';
import 'core/services/fcm_notification_service.dart';
import 'core/utils/app_logger.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final FCMNotificationService _fcmService = FCMNotificationService();

  @override
  void dispose() {
    _fcmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('MyApp building');

    // Get the router from provider
    final router = ref.watch(appRouterProvider);

    AppLogger.debug('Router loaded: ${router.routeInformationProvider.value.uri}');

    // Listen to auth state for FCM initialization only
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // User logged in - initialize FCM
          _fcmService.initialize(user.uid);

          // Subscribe to admin topics based on role
          if (user.isSuperAdmin) {
            _fcmService.subscribeToTopic('super_admins');
            _fcmService.subscribeToTopic('admins');
          } else if (user.isAdmin) {
            _fcmService.subscribeToTopic('admins');
          }
        } else {
          // User logged out - delete FCM token
          _fcmService.deleteToken();
        }
      });
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
