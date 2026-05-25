import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/core/config/env/environment.dart';
import 'package:admin_dashboard/core/config/models/app_config.dart';
import 'package:admin_dashboard/core/config/models/auth_config.dart';
import 'package:admin_dashboard/core/config/models/firestore_config.dart';
import 'package:admin_dashboard/core/config/models/elasticsearch_config.dart';
import 'package:admin_dashboard/core/config/models/feature_flags_config.dart';

// ============ Core Configuration Providers ============

/// Global app configuration provider
/// This provider makes the AppConfig available throughout the app
/// Depends on the current environment
final appConfigProvider = Provider<AppConfig>((ref) {
  final environment = getCurrentEnvironment();
  return AppConfig.forEnvironment(environment);
});

/// Environment provider
final environmentProvider = Provider<Environment>((ref) {
  return getCurrentEnvironment();
});

/// App name provider
final appNameProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.appName;
});

/// App version provider
final appVersionProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return '${config.appVersion}+${config.buildNumber}';
});

// ============ Feature-Specific Configuration Providers ============

/// Debug mode provider
final debugModeProvider = Provider<bool>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.debugMode;
});

/// Logging enabled provider
final loggingEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.enableLogging;
});

/// Log level provider
final logLevelProvider = Provider<int>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.logLevel;
});

/// Feature flags provider
final featureFlagsProvider = Provider<FeatureFlagsConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.featureFlags;
});

/// Auth config provider
final authConfigProvider = Provider<AuthConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.authConfig;
});

/// Firestore config provider
final firestoreConfigProvider = Provider<FirestoreConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.firestoreConfig;
});

/// Elasticsearch config provider
final elasticsearchConfigProvider = Provider<ElasticsearchConfig>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.elasticsearchConfig;
});

// ============ Feature Flag Providers ============

/// Check if elasticsearch search is enabled
final isElasticsearchEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableElasticsearchSearch;
});

/// Check if mock data is enabled (dev only)
final isMockDataEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableMockData;
});

/// Check if audit logging is enabled
final isAuditLoggingEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableAuditLogging;
});

/// Check if notifications are enabled
final areNotificationsEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableNotifications;
});

/// Check if bulk actions are enabled
final areBulkActionsEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableBulkActions;
});

/// Check if invoices are enabled
final areInvoicesEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableInvoices;
});

/// Check if affiliates are enabled
final areAffiliatesEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableAffiliates;
});

/// Check if vendors are enabled
final areVendorsEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableVendors;
});

/// Check if shipping is enabled
final isShippingEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableShipping;
});

/// Check if advanced filtering is enabled
final isAdvancedFilteringEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableAdvancedFiltering;
});

/// Check if analytics are enabled
final isAnalyticsEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableAnalytics;
});

/// Check if experimental features are enabled
final areExperimentalFeaturesEnabledProvider = Provider<bool>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.enableExperimentalFeatures;
});

// ============ Security Configuration Providers ============

/// Two-factor authentication enabled provider
final isTwoFactorEnabledProvider = Provider<bool>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.enableTwoFactor;
});

/// Email verification required provider
final isEmailVerificationRequiredProvider = Provider<bool>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.requireEmailVerification;
});

/// Session timeout provider
final sessionTimeoutProvider = Provider<Duration>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.sessionTimeout;
});

/// Max login attempts provider
final maxLoginAttemptsProvider = Provider<int>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.maxLoginAttempts;
});

/// Lockout duration provider
final lockoutDurationProvider = Provider<Duration>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  return authConfig.lockoutDuration;
});

// ============ Database Configuration Providers ============

/// Offline persistence enabled provider
final isOfflinePersistenceEnabledProvider = Provider<bool>((ref) {
  final firestoreConfig = ref.watch(firestoreConfigProvider);
  return firestoreConfig.enableOfflinePersistence;
});

/// Caching enabled provider
final isCachingEnabledProvider = Provider<bool>((ref) {
  final firestoreConfig = ref.watch(firestoreConfigProvider);
  return firestoreConfig.enableCaching;
});

/// Cache duration provider
final cacheDurationProvider = Provider<Duration>((ref) {
  final firestoreConfig = ref.watch(firestoreConfigProvider);
  return firestoreConfig.cacheDuration;
});

// ============ Environment-Specific Providers ============

/// Check if running in development
final isDevEnvironmentProvider = Provider<bool>((ref) {
  final env = ref.watch(environmentProvider);
  return env.isDevelopment;
});

/// Check if running in staging
final isStagingEnvironmentProvider = Provider<bool>((ref) {
  final env = ref.watch(environmentProvider);
  return env.isStaging;
});

/// Check if running in production
final isProdEnvironmentProvider = Provider<bool>((ref) {
  final env = ref.watch(environmentProvider);
  return env.isProduction;
});

/// Check if NOT production
final isNotProdEnvironmentProvider = Provider<bool>((ref) {
  final env = ref.watch(environmentProvider);
  return env.isNotProduction;
});

/// Environment display name provider
final environmentDisplayNameProvider = Provider<String>((ref) {
  final env = ref.watch(environmentProvider);
  return env.displayName;
});
