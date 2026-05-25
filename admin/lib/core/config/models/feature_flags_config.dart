/// Feature flags configuration
/// Controls which features are enabled/disabled across environments
class FeatureFlagsConfig {
  final bool enableNotifications;
  final bool enableBulkActions;
  final bool enableInvoices;
  final bool enableAffiliates;
  final bool enableVendors;
  final bool enableShipping;
  final bool enableElasticsearchSearch;
  final bool enableAdvancedFiltering;
  final bool enableAnalytics;
  final bool enableAuditLogging;
  final bool enableMockData;
  final bool enableExperimentalFeatures;

  FeatureFlagsConfig({
    required this.enableNotifications,
    required this.enableBulkActions,
    required this.enableInvoices,
    required this.enableAffiliates,
    required this.enableVendors,
    required this.enableShipping,
    required this.enableElasticsearchSearch,
    required this.enableAdvancedFiltering,
    required this.enableAnalytics,
    required this.enableAuditLogging,
    required this.enableMockData,
    required this.enableExperimentalFeatures,
  });

  factory FeatureFlagsConfig.development() {
    return FeatureFlagsConfig(
      enableNotifications: true,
      enableBulkActions: true,
      enableInvoices: true,
      enableAffiliates: true,
      enableVendors: true,
      enableShipping: true,
      enableElasticsearchSearch: true,
      enableAdvancedFiltering: true,
      enableAnalytics: true,
      enableAuditLogging: true,
      enableMockData: true,
      enableExperimentalFeatures: true,
    );
  }

  factory FeatureFlagsConfig.staging() {
    return FeatureFlagsConfig(
      enableNotifications: true,
      enableBulkActions: true,
      enableInvoices: true,
      enableAffiliates: true,
      enableVendors: true,
      enableShipping: true,
      enableElasticsearchSearch: true,
      enableAdvancedFiltering: true,
      enableAnalytics: true,
      enableAuditLogging: true,
      enableMockData: false,
      enableExperimentalFeatures: true,
    );
  }

  factory FeatureFlagsConfig.production() {
    return FeatureFlagsConfig(
      enableNotifications: true,
      enableBulkActions: true,
      enableInvoices: true,
      enableAffiliates: true,
      enableVendors: true,
      enableShipping: true,
      enableElasticsearchSearch: true,
      enableAdvancedFiltering: true,
      enableAnalytics: true,
      enableAuditLogging: true,
      enableMockData: false,
      enableExperimentalFeatures: false,
    );
  }
}
