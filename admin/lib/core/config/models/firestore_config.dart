/// Firestore database configuration
/// Handles all Firestore-specific settings including caching, batch operations, and collection paths
class FirestoreConfig {
  final bool enableOfflinePersistence;
  final bool enableCaching;
  final Duration cacheDuration;
  final int maxBatchReadSize;
  final int maxBatchWriteSize;
  final Duration queryTimeout;
  final bool enableLogging;
  final Map<String, String> collectionPaths;

  FirestoreConfig({
    required this.enableOfflinePersistence,
    required this.enableCaching,
    required this.cacheDuration,
    required this.maxBatchReadSize,
    required this.maxBatchWriteSize,
    required this.queryTimeout,
    required this.enableLogging,
    required this.collectionPaths,
  });

  factory FirestoreConfig.development() {
    return FirestoreConfig(
      enableOfflinePersistence: true,
      enableCaching: true,
      cacheDuration: const Duration(hours: 1),
      maxBatchReadSize: 100,
      maxBatchWriteSize: 100,
      queryTimeout: const Duration(seconds: 30),
      enableLogging: true,
      collectionPaths: {
        'users': 'users',
        'admins': 'admins',
        'reviews': 'reviews',
        'invoices': 'invoices',
        'orders': 'orders',
        'products': 'products',
        'customers': 'customers',
        'content': 'content',
        'banners': 'banners',
        'faqs': 'faqs',
        'email_templates': 'email_templates',
        'settings': 'settings',
        'admin_activity': 'admin_activity',
        'settings_history': 'settings_history',
      },
    );
  }

  factory FirestoreConfig.staging() {
    return FirestoreConfig(
      enableOfflinePersistence: true,
      enableCaching: true,
      cacheDuration: const Duration(hours: 2),
      maxBatchReadSize: 500,
      maxBatchWriteSize: 500,
      queryTimeout: const Duration(seconds: 60),
      enableLogging: true,
      collectionPaths: {
        'users': 'users',
        'admins': 'admins',
        'reviews': 'reviews',
        'invoices': 'invoices',
        'orders': 'orders',
        'products': 'products',
        'customers': 'customers',
        'content': 'content',
        'banners': 'banners',
        'faqs': 'faqs',
        'email_templates': 'email_templates',
        'settings': 'settings',
        'admin_activity': 'admin_activity',
        'settings_history': 'settings_history',
      },
    );
  }

  factory FirestoreConfig.production() {
    return FirestoreConfig(
      enableOfflinePersistence: true,
      enableCaching: true,
      cacheDuration: const Duration(hours: 4),
      maxBatchReadSize: 500,
      maxBatchWriteSize: 500,
      queryTimeout: const Duration(seconds: 60),
      enableLogging: false,
      collectionPaths: {
        'users': 'users',
        'admins': 'admins',
        'reviews': 'reviews',
        'invoices': 'invoices',
        'orders': 'orders',
        'products': 'products',
        'customers': 'customers',
        'content': 'content',
        'banners': 'banners',
        'faqs': 'faqs',
        'email_templates': 'email_templates',
        'settings': 'settings',
        'admin_activity': 'admin_activity',
        'settings_history': 'settings_history',
      },
    );
  }

  /// Get collection path by name
  String getCollectionPath(String collectionName) =>
      collectionPaths[collectionName] ?? collectionName;

  /// Check if offline persistence is enabled
  bool get hasOfflinePersistence => enableOfflinePersistence;

  /// Get effective cache duration (max 24 hours)
  Duration get effectiveCacheDuration =>
      cacheDuration > const Duration(hours: 24)
      ? const Duration(hours: 24)
      : cacheDuration;

  @override
  String toString() =>
      'FirestoreConfig(offline: $enableOfflinePersistence, cache: $enableCaching, timeout: $queryTimeout)';
}
