import 'package:admin_dashboard/features/settings/data/models/index.dart';

/// Abstract interface for settings operations
abstract class ISettingsRepository {
  // User Preferences
  Future<UserPreferences?> getUserPreferences(String userId);
  Future<void> updateUserPreferences(String userId, UserPreferences prefs);
  Future<void> setThemePreference(String userId, ThemePreference theme);
  Future<void> setLanguage(String userId, String language);
  Future<void> setTimezone(String userId, String timezone);
  Future<void> toggleNotifications(String userId, bool enabled);
  Future<void> setQuietHours(String userId, String? start, String? end);
  Future<void> enable2FA(String userId, String phoneNumber);
  Future<void> disable2FA(String userId);
  Future<void> addFavoriteModule(String userId, String moduleName);
  Future<void> removeFavoriteModule(String userId, String moduleName);
  Future<void> recordLastLogin(String userId);

  // Business Settings
  Future<BusinessSettings> getBusinessSettings();
  Future<void> updateBusinessSettings(BusinessSettings settings);
  Future<void> updateBusinessInfo(
    String name,
    String email,
    String phone,
    String website,
  );
  Future<void> updateTaxSettings(String? taxId, double? rate);
  Future<void> addShippingZone(ShippingZone zone);
  Future<void> updateShippingZone(String zoneId, ShippingZone zone);
  Future<void> removeShippingZone(String zoneId);
  Future<void> addPaymentMethod(PaymentMethod method);
  Future<void> updatePaymentMethod(String methodId, PaymentMethod method);
  Future<void> removePaymentMethod(String methodId);
  Future<void> setDefaultPaymentMethod(String methodId);
  Future<List<BusinessSettingsHistory>> getSettingsHistory({int limit = 50});
  Future<void> rollbackSettings(int version);

  // API Settings
  Future<APISettings> getAPISettings();
  Future<void> updateAPISettings(APISettings settings);
  Future<void> updateStripeSettings(String publishableKey, String secretKey);
  Future<void> updatePayPalSettings(String clientId, String secret);
  Future<void> updateAWSSettings(
    String accessKey,
    String secretKey,
    String region,
    String bucket,
  );
  Future<void> updateSendGridSettings(String apiKey, String fromEmail);
  Future<void> updateTwilioSettings(
    String accountSid,
    String authToken,
    String phone,
  );
  Future<void> updateElasticsearchSettings(String url, String apiKey);
  Future<void> setWebhookSecret(String service, String secret);
  Future<Map<String, dynamic>> validateAPIConnection(String service);
}

/// History record for settings changes (version history)
class BusinessSettingsHistory {
  final int version;
  final String changedBy;
  final DateTime changedAt;
  final Map<String, dynamic> previousValues;
  final Map<String, dynamic> newValues;

  BusinessSettingsHistory({
    required this.version,
    required this.changedBy,
    required this.changedAt,
    required this.previousValues,
    required this.newValues,
  });
}
