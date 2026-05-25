import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import only ProviderScope from Riverpod to avoid exporting ChangeNotifierProvider
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderScope, Consumer;
// NavigatorKey is provided by flutter/material above
// To override providers in development, import your providers and mock repos
// and pass them to ProviderScope.overrides. Example:
// import 'package:shopsnports/providers/user_providers.dart';
// import 'package:shopsnports/repositories/mock_user_repository.dart';
import 'package:shopsnports/styles/theme.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/models/user.dart';
import 'package:shopsnports/services/notification_service.dart';
import 'package:shopsnports/providers/geolocation_provider.dart';
import 'package:shopsnports/services/analytics_service.dart';
import 'package:shopsnports/utils/app_logger.dart';
import 'package:shopsnports/utils/deep_link_handler.dart';
// import 'package:shopsnports/screens/payment_verifying_screen.dart';
import 'package:shopsnports/core/config/app_config.dart';
import 'package:shopsnports/core/routing/app_router.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/widgets/error_boundary.dart';
import 'package:shopsnports/screens/splash/animated_splash_screen.dart';
import 'firebase_options_production.dart';
// import 'package:shopsnports/screens/orders/orders_list_screen.dart';
// import 'package:shopsnports/screens/cart/payment_methods_screen.dart';
// unused: checkout import removed; individual screens import it where needed

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling
  GlobalErrorHandler.initialize();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Initialize deep link handler (no init needed for this minimal implementation)

  // Validate configuration
  AppConfig.validate();

  // Initialize analytics (best-effort). This will use Firebase Analytics
  // when available and fall back to console logging otherwise.
  await AnalyticsService.instance.init();
  // Emit a debug-only smoke event so we can verify Firebase DebugView quickly.
  // This runs only in debug mode and will be ignored in release builds.
  if (kDebugMode) {
    AnalyticsService.instance
        .logEvent('debug_smoke_app_start', {'env': 'debug'});
  }
  // Start the app with normal auth flow
  runApp(const ProviderScope(child: MyApp()));
}

// Top-level navigator key so background services can show dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer at the top level so we can call provider init after the
    // first frame (ProviderScope is already mounted in runApp).
    return Consumer(builder: (context, ref, _) {
      // best-effort init; errors are swallowed inside init()
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ref.read(geolocationProvider.notifier).init();
          // This is best-effort and won't block app startup.
          NotificationService.instance.init().catchError((_) {});
          // DISABLED FOR TESTING: Auto sign-out on startup
          // In debug builds, force a sign-out on startup so the app
          // shows the login action by default for manual testing.
          // This is a no-op in release builds.
          // FIXED: Removed duplicate signOut calls to prevent concurrent operations error
          // TODO: Re-enable before production deployment
          // if (AppConfig.forceSignOutOnStart || kDebugMode) {
          //   try {
          //     ref.read(authActionsProvider).signOut();
          //   } catch (_) {}
          // }
          // Attempt to read a one-shot initial deep link (if app was opened
          // via myapp://...). This relies on a minimal platform bridge on
          // Android that returns the initial intent data. The handler will
          // navigate to the appropriate screen based on the deep link pattern.
          try {
            // Call the minimal deep link handler and navigate if needed.
            DeepLinkHandler.getInitialLink().then((uriString) {
              if (uriString == null) {
                return;
              }
              try {
                final uri = Uri.parse(uriString);
                AppLogger.info(
                    'Processing deep link: ${uri.host} with params: ${uri.queryParameters}');

                // Payment deep links no longer supported - payments done manually via transfer
                // Handle affiliate invitation deep links
                if (uri.host == 'affiliate' && uri.queryParameters.containsKey('code')) {
                  final affiliateCode = uri.queryParameters['code'];
                  AppLogger.info('Processing affiliate invitation with code: $affiliateCode');
                  // Navigate to affiliate intro with the referral code
                  if (navigatorKey.currentContext != null) {
                    Navigator.of(navigatorKey.currentContext!).pushNamed(
                      AppRoutes.affiliateIntro,
                      arguments: {'referralCode': affiliateCode},
                    );
                  }
                }
              } catch (e, stackTrace) {
                AppLogger.error('Failed to process deep link', e, stackTrace);
              }
            });
          } catch (e, stackTrace) {
            AppLogger.error(
                'Failed to initialize deep link handler', e, stackTrace);
          }
        } catch (_) {}
      });

      // Deep link handler is called above inside the first post-frame callback.

      // Watch currentUserProvider and subscribe/unsubscribe to admin topic
      // when user changes. This must be done during build (ref.listen only
      // allowed inside build of ConsumerWidget/Consumer). We call the
      // NotificationService methods without awaiting so they run
      // asynchronously and don't block the listener.
      ref.listen<AppUser?>(currentUserProvider, (previous, next) {
        try {
          if (next != null && next.isAdmin == true) {
            NotificationService.instance.subscribeToAdminsTopic();
          } else {
            NotificationService.instance.unsubscribeFromAdminsTopic();
          }

          final prevAff = previous?.affiliateId;
          final nextAff = next?.affiliateId;
          if (prevAff != null && prevAff != nextAff) {
            NotificationService.instance.unsubscribeFromAffiliateTopic(prevAff);
          }
          if (nextAff != null) {
            NotificationService.instance.subscribeToAffiliateTopic(nextAff);
          }
          // Subscribe to a per-user topic so server functions can target this
          // user specifically regardless of role.
          final prevUid = previous?.id;
          final nextUid = next?.id;
          if (prevUid != null && prevUid != nextUid) {
            NotificationService.instance.unsubscribeFromUserTopic(prevUid);
          }
          if (nextUid != null) {
            NotificationService.instance.subscribeToUserTopic(nextUid);
          }
        } catch (_) {}
      });

      return MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ShopsNports',
        theme: themeData,
        debugShowCheckedModeBanner: false,
        // Launch screen shows splash with first-launch detection:
        // - First time: 4-slide promotional splash (20s)
        // - Returning: Skip to home/landing immediately
        home: const AnimatedSplashScreen(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        // Fallback for unknown routes
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        ),
      );
    });
  }
}
