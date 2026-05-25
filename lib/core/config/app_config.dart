/// Application Configuration
///
/// Firebase-only architecture - Firestore is the single source of truth
///
/// Usage in build:
/// flutter run --dart-define=ENVIRONMENT=development
/// flutter build apk --dart-define=ENVIRONMENT=production
library;

class AppConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Firebase Configuration
  static const String firebaseProjectId = 'shopsnports';

  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );

  // Environment checks
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // Debugging
  static bool get enableDebugLogs => isDevelopment || isStaging;
  static bool get forceSignOutOnStart => isDevelopment; // Only in dev

  /// Validates that the config values are set correctly for the current build.
  static void validate() {
    assert(environment == 'development' ||
        environment == 'staging' ||
        environment == 'production');
    if (!isDevelopment && !isStaging && !isProduction) {
      throw StateError('Unsupported environment: $environment');
    }
  }
}
