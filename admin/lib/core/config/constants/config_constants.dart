/// Configuration constants
/// Contains all hard-coded configuration values used throughout the app
class ConfigConstants {
  // ============ Firestore Collections ============
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String adminActivityCollection = 'admin_activity';
  static const String adminRegistrationsCollection = 'admin_registrations';
  static const String contentCollection = 'content';
  static const String bannersCollection = 'banners';
  static const String faqCollection = 'faqs';
  static const String emailTemplatesCollection = 'email_templates';
  static const String settingsCollection = 'settings';
  static const String businessSettingsDoc = 'business_settings';
  static const String settingsHistoryCollection = 'settings_history';
  static const String notificationsCollection = 'notifications';
  static const String ordersCollection = 'orders';
  static const String invoicesCollection = 'invoices';
  static const String productsCollection = 'products';
  static const String customersCollection = 'customers';
  static const String reviewsCollection = 'reviews';
  static const String vendorsCollection = 'vendors';
  static const String affiliatesCollection = 'affiliates';
  static const String shippingCollection = 'shipping_zones';

  // ============ Elasticsearch Index Names ============
  static const String reviewsIndexPrefix = 'reviews';
  static const String invoicesIndexPrefix = 'invoices';
  static const String ordersIndexPrefix = 'orders';
  static const String productsIndexPrefix = 'products';
  static const String contentIndexPrefix = 'content';
  static const String customersIndexPrefix = 'customers';

  // ============ API Timeouts ============
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration firebaseTimeout = Duration(seconds: 60);
  static const Duration elasticsearchTimeout = Duration(seconds: 45);
  static const Duration fileUploadTimeout = Duration(minutes: 5);

  // ============ Pagination ============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 5;

  // ============ Caching Durations ============
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const Duration userPreferencesCacheDuration = Duration(hours: 24);
  static const Duration businessSettingsCacheDuration = Duration(days: 1);
  static const Duration productsCacheDuration = Duration(hours: 2);
  static const Duration contentCacheDuration = Duration(hours: 4);
  static const Duration settingsCacheDuration = Duration(hours: 6);

  // ============ Security ============
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration tokenRefreshInterval = Duration(hours: 23);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int sessionInactivityTimeout = 900; // 15 minutes in seconds

  // ============ Admin Activity & Audit Logging ============
  static const int maxActivityLogSize = 10000;
  static const Duration activityLogRetention = Duration(days: 90);
  static const int activityLogPageSize = 50;
  static const List<String> auditableActions = [
    'create',
    'update',
    'delete',
    'approve',
    'reject',
    'publish',
    'unpublish',
    'export',
    'import',
    'bulk_action',
  ];

  // ============ Bulk Operations ============
  static const int maxBulkOperationSize = 500;
  static const int bulkOperationTimeout = 300; // seconds
  static const int maxConcurrentBulkOps = 5;

  // ============ File Upload ============
  static const int maxFileSize = 52428800; // 50 MB
  static const int maxImageSize = 10485760; // 10 MB
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> allowedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
  ];

  // ============ Notifications ============
  static const Duration notificationRetention = Duration(days: 30);
  static const int maxNotificationsPerUser = 1000;
  static const Duration notificationCleanupInterval = Duration(days: 1);

  // ============ Rate Limiting ============
  static const int apiCallsPerMinute = 60;
  static const int apiCallsPerHour = 1000;
  static const int searchQueriesPerMinute = 30;

  // ============ Search ============
  static const int minSearchLength = 2;
  static const int maxSearchLength = 200;
  static const int searchSuggestionLimit = 10;
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // ============ Email ============
  static const int maxEmailRecipientsPerBatch = 100;
  static const Duration emailRetryInterval = Duration(minutes: 5);
  static const int maxEmailRetries = 3;

  // ============ Analytics ============
  static const Duration analyticsRetention = Duration(days: 365);
  static const int analyticsReportLimit = 10000;

  // ============ Feature Flags ============
  static const bool defaultEnableNotifications = true;
  static const bool defaultEnableAnalytics = true;
  static const bool defaultEnableAuditLogging = true;
  static const bool defaultEnableElasticsearch =
      false; // Start with false, enable in higher envs

  // ============ Version Info ============
  static const String apiVersion = '1.0.0';
  static const String minimumSupportedVersion = '1.0.0';
  static const String currentBuildNumber = '1';
}
