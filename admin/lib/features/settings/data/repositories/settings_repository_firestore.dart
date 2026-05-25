import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_dashboard/features/settings/data/models/api_settings.dart';
import 'package:admin_dashboard/features/settings/data/models/business_settings.dart';
import 'package:admin_dashboard/features/settings/data/models/user_preferences.dart';
import 'package:admin_dashboard/features/settings/data/repositories/settings_repository.dart';

/// Firestore implementation of ISettingsRepository
class SettingsRepositoryFirestore implements ISettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _userPreferencesCollection =>
      _firestore.collection('user_preferences');
  CollectionReference get _businessSettingsCollection =>
      _firestore.collection('business_settings');

  // ========== USER PREFERENCES ==========

  @override
  Future<UserPreferences> getUserPreferences(String userId) async {
    final doc = await _userPreferencesCollection.doc(userId).get();
    if (!doc.exists) {
      // Return default preferences
      return UserPreferences.defaults(userId);
    }
    return UserPreferences.fromMap(doc.data() as Map<String, dynamic>, userId);
  }

  @override
  Future<void> updateUserPreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    await _userPreferencesCollection
        .doc(userId)
        .set(preferences.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> setThemePreference(String userId, ThemePreference theme) async {
    await _userPreferencesCollection.doc(userId).update({
      'theme': theme.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setLanguage(String userId, String language) async {
    await _userPreferencesCollection.doc(userId).update({
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setTimezone(String userId, String timezone) async {
    await _userPreferencesCollection.doc(userId).update({
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleNotifications(
    String userId,
    bool enableNotifications,
  ) async {
    await _userPreferencesCollection.doc(userId).update({
      'enableNotifications': enableNotifications,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setQuietHours(String userId, String? start, String? end) async {
    await _userPreferencesCollection.doc(userId).update({
      'quietHoursStart': start,
      'quietHoursEnd': end,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> enable2FA(String userId, String phoneNumber) async {
    await _userPreferencesCollection.doc(userId).update({
      'enableTwoFactor': true,
      'phoneNumberFor2FA': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> disable2FA(String userId) async {
    await _userPreferencesCollection.doc(userId).update({
      'enableTwoFactor': false,
      'phoneNumberFor2FA': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addFavoriteModule(String userId, String moduleId) async {
    await _userPreferencesCollection.doc(userId).update({
      'favoriteModules': FieldValue.arrayUnion([moduleId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFavoriteModule(String userId, String moduleId) async {
    await _userPreferencesCollection.doc(userId).update({
      'favoriteModules': FieldValue.arrayRemove([moduleId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> recordLastLogin(String userId) async {
    await _userPreferencesCollection.doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // ========== BUSINESS SETTINGS ==========

  @override
  Future<BusinessSettings> getBusinessSettings() async {
    // Use a fixed document ID for global business settings
    final doc = await _businessSettingsCollection.doc('global').get();
    if (!doc.exists) {
      // Return default business settings
      return BusinessSettings.defaults();
    }
    return BusinessSettings.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> updateBusinessSettings(BusinessSettings settings) async {
    // Increment version
    final updatedSettings = settings.copyWith(
      version: settings.version + 1,
      updatedAt: DateTime.now(),
    );
    await _businessSettingsCollection
        .doc('global')
        .set(updatedSettings.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateBusinessInfo(
    String name,
    String email,
    String phone,
    String website,
  ) async {
    await _businessSettingsCollection.doc('global').update({
      'businessName': name,
      'businessEmail': email,
      'businessPhone': phone,
      'businessWebsite': website,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateTaxSettings(String? taxId, double? rate) async {
    final updates = <String, dynamic>{};
    if (taxId != null) updates['taxId'] = taxId;
    if (rate != null) updates['taxRate'] = rate;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    if (updates.isNotEmpty) {
      await _businessSettingsCollection.doc('global').update(updates);
    }
  }

  @override
  Future<void> addShippingZone(ShippingZone zone) async {
    final settings = await getBusinessSettings();
    final zones = List<ShippingZone>.from(settings.shippingZones);
    zones.add(zone);
    await _businessSettingsCollection.doc('global').update({
      'shippingZones': zones.map((z) => z.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateShippingZone(String id, ShippingZone zone) async {
    final settings = await getBusinessSettings();
    final zones = settings.shippingZones
        .map((z) => z.id == id ? zone : z)
        .toList();
    await _businessSettingsCollection.doc('global').update({
      'shippingZones': zones.map((z) => z.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeShippingZone(String id) async {
    final settings = await getBusinessSettings();
    final zones = settings.shippingZones.where((z) => z.id != id).toList();
    await _businessSettingsCollection.doc('global').update({
      'shippingZones': zones.map((z) => z.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addPaymentMethod(PaymentMethod method) async {
    final settings = await getBusinessSettings();
    final methods = List<PaymentMethod>.from(settings.paymentMethods);
    methods.add(method);
    await _businessSettingsCollection.doc('global').update({
      'paymentMethods': methods.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updatePaymentMethod(String id, PaymentMethod method) async {
    final settings = await getBusinessSettings();
    final methods = settings.paymentMethods
        .map((m) => m.id == id ? method : m)
        .toList();
    await _businessSettingsCollection.doc('global').update({
      'paymentMethods': methods.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removePaymentMethod(String id) async {
    final settings = await getBusinessSettings();
    final methods = settings.paymentMethods.where((m) => m.id != id).toList();
    await _businessSettingsCollection.doc('global').update({
      'paymentMethods': methods.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setDefaultPaymentMethod(String id) async {
    final settings = await getBusinessSettings();
    final methods = settings.paymentMethods
        .map((m) => m.copyWith(isDefault: m.id == id))
        .toList();
    await _businessSettingsCollection.doc('global').update({
      'paymentMethods': methods.map((m) => m.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== SETTINGS HISTORY ==========

  @override
  Future<List<BusinessSettingsHistory>> getSettingsHistory({
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('settings_history')
        .orderBy('changedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BusinessSettingsHistory(
        version: data['version'] ?? 1,
        changedBy: data['changedBy'] ?? 'system',
        changedAt:
            (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        previousValues: Map<String, dynamic>.from(data['previousValues'] ?? {}),
        newValues: Map<String, dynamic>.from(data['newValues'] ?? {}),
      );
    }).toList();
  }

  @override
  Future<void> rollbackSettings(int version) async {
    // Stub: Not fully implemented - would need to restore from history
    throw UnimplementedError(
      'Settings rollback not implemented in Firestore version',
    );
  }

  // ========== API SETTINGS ==========

  @override
  Future<APISettings> getAPISettings() async {
    // Return empty settings since API settings are not yet migrated to Firestore
    return APISettings.empty();
  }

  @override
  Future<void> updateAPISettings(APISettings settings) async {
    throw UnimplementedError(
      'API settings update not implemented in Firestore version',
    );
  }

  @override
  Future<void> updateStripeSettings(
    String publishableKey,
    String secretKey,
  ) async {
    throw UnimplementedError('Stripe settings not implemented');
  }

  @override
  Future<void> updatePayPalSettings(String clientId, String secret) async {
    throw UnimplementedError('PayPal settings not implemented');
  }

  @override
  Future<void> updateAWSSettings(
    String accessKey,
    String secretKey,
    String region,
    String bucket,
  ) async {
    throw UnimplementedError('AWS settings not implemented');
  }

  @override
  Future<void> updateSendGridSettings(String apiKey, String fromEmail) async {
    throw UnimplementedError('SendGrid settings not implemented');
  }

  @override
  Future<void> updateTwilioSettings(
    String accountSid,
    String authToken,
    String phone,
  ) async {
    throw UnimplementedError('Twilio settings not implemented');
  }

  @override
  Future<void> updateElasticsearchSettings(String url, String apiKey) async {
    throw UnimplementedError('Elasticsearch settings not implemented');
  }

  @override
  Future<void> setWebhookSecret(String service, String secret) async {
    throw UnimplementedError('Webhook secrets not implemented');
  }

  @override
  Future<Map<String, dynamic>> validateAPIConnection(String service) async {
    throw UnimplementedError('API validation not implemented');
  }

  // ==================== SEEDING ====================

  /// Seed sample settings data
  Future<void> seedSampleData() async {
    try {
      // Check if already seeded
      final existing = await _businessSettingsCollection.limit(1).get();
      if (existing.docs.isNotEmpty) {
        print('Settings already seeded');
        return;
      }

      final now = DateTime.now();

      // Seed Business Settings
      final businessSettings = {
        'businessName': 'ShopsNPorts',
        'businessEmail': 'info@shopsnports.com',
        'businessPhone': '+234 800 123 4567',
        'businessAddress': '123 Lagos Street, Victoria Island, Lagos, Nigeria',
        'currency': 'NGN',
        'currencySymbol': '₦',
        'timezone': 'Africa/Lagos',
        'taxRate': 7.5,
        'enableTax': true,
        'defaultCommissionRate': 10.0,
        'minPayoutAmount': 5000.0,
        'paymentGateways': {
          'paystack': {
            'enabled': true,
            'publicKey': 'pk_test_xxxxx',
            'secretKey': 'sk_test_xxxxx',
          },
          'flutterwave': {
            'enabled': true,
            'publicKey': 'FLWPUBK_TEST-xxxxx',
            'secretKey': 'FLWSECK_TEST-xxxxx',
          },
        },
        'shippingZones': [
          {'name': 'Lagos', 'baseCost': 2500.0, 'perKgCost': 500.0},
          {'name': 'Abuja', 'baseCost': 3500.0, 'perKgCost': 700.0},
          {'name': 'Port Harcourt', 'baseCost': 4000.0, 'perKgCost': 800.0},
          {'name': 'Other Regions', 'baseCost': 5000.0, 'perKgCost': 1000.0},
        ],
        'maintenanceMode': false,
        'maintenanceMessage': '',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _businessSettingsCollection.doc('global').set(businessSettings);

      // Seed User Preferences for default admin
      final userPreferences = {
        'theme': 'system',
        'language': 'en',
        'timezone': 'Africa/Lagos',
        'enableNotifications': true,
        'quietHoursStart': null,
        'quietHoursEnd': null,
        'enableTwoFactor': false,
        'phoneNumberFor2FA': null,
        'dashboardLayout': 'default',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _userPreferencesCollection.doc('admin_001').set(userPreferences);

      print('✅ Seeded business settings and user preferences');
    } catch (e) {
      print('Error seeding settings: $e');
      rethrow;
    }
  }
}
