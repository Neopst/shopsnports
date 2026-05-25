import 'package:admin_dashboard/core/config/env/environment.dart';
import 'package:admin_dashboard/core/config/models/auth_config.dart';
import 'package:admin_dashboard/core/config/models/firestore_config.dart';
import 'package:admin_dashboard/core/config/models/elasticsearch_config.dart';
import 'package:admin_dashboard/core/config/models/feature_flags_config.dart';

/// Main application configuration
/// Contains all environment-specific settings
class AppConfig {
  final Environment environment;
  final String appName;
  final String appVersion;
  final String buildNumber;
  final bool debugMode;
  final AuthConfig authConfig;
  final FirestoreConfig firestoreConfig;
  final ElasticsearchConfig elasticsearchConfig;
  final FeatureFlagsConfig featureFlags;
  final bool enableLogging;
  final int logLevel; // 0: verbose, 1: debug, 2: info, 3: warning, 4: error

  AppConfig({
    required this.environment,
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.debugMode,
    required this.authConfig,
    required this.firestoreConfig,
    required this.elasticsearchConfig,
    required this.featureFlags,
    required this.enableLogging,
    required this.logLevel,
  });

  /// Create development configuration
  factory AppConfig.development() {
    return AppConfig(
      environment: Environment.development,
      appName: 'Admin Dashboard',
      appVersion: '1.0.0',
      buildNumber: '1',
      debugMode: true,
      authConfig: AuthConfig.development(),
      firestoreConfig: FirestoreConfig.development(),
      elasticsearchConfig: ElasticsearchConfig.development(),
      featureFlags: FeatureFlagsConfig.development(),
      enableLogging: true,
      logLevel: 0, // verbose
    );
  }

  /// Create staging configuration
  factory AppConfig.staging() {
    return AppConfig(
      environment: Environment.staging,
      appName: 'Admin Dashboard',
      appVersion: '1.0.0',
      buildNumber: '1',
      debugMode: false,
      authConfig: AuthConfig.staging(),
      firestoreConfig: FirestoreConfig.staging(),
      elasticsearchConfig: ElasticsearchConfig.staging(),
      featureFlags: FeatureFlagsConfig.staging(),
      enableLogging: true,
      logLevel: 1, // debug
    );
  }

  /// Create production configuration
  factory AppConfig.production() {
    return AppConfig(
      environment: Environment.production,
      appName: 'Admin Dashboard',
      appVersion: '1.0.0',
      buildNumber: '1',
      debugMode: false,
      authConfig: AuthConfig.production(),
      firestoreConfig: FirestoreConfig.production(),
      elasticsearchConfig: ElasticsearchConfig.production(),
      featureFlags: FeatureFlagsConfig.production(),
      enableLogging: true,
      logLevel: 3, // warning
    );
  }

  /// Get configuration for current environment
  factory AppConfig.forEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        return AppConfig.development();
      case Environment.staging:
        return AppConfig.staging();
      case Environment.production:
        return AppConfig.production();
    }
  }

  bool get isDevelopment => environment.isDevelopment;
  bool get isStaging => environment.isStaging;
  bool get isProduction => environment.isProduction;

  @override
  String toString() {
    return 'AppConfig(env: ${environment.name}, version: $appVersion+$buildNumber)';
  }
}
