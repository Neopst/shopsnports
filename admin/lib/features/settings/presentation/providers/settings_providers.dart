import 'package:admin_dashboard/features/settings/data/models/index.dart';
import 'package:admin_dashboard/features/settings/data/repositories/index.dart';
import 'package:admin_dashboard/features/settings/data/repositories/settings_repository_firestore.dart';
import 'package:riverpod/riverpod.dart';

// Repository provider (using Firestore implementation)
final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  return SettingsRepositoryFirestore();
  // return SettingsRepositoryMock(); // OLD: Mock data
});

// User Preferences Providers
final userPreferencesProvider = FutureProvider.family<UserPreferences?, String>(
  (ref, userId) async {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.getUserPreferences(userId);
  },
);

final updateUserPreferencesFamilyProvider =
    FutureProvider.family<void, (String, UserPreferences)>((ref, params) async {
      final repo = ref.watch(settingsRepositoryProvider);
      final (userId, prefs) = params;
      await repo.updateUserPreferences(userId, prefs);
      // Invalidate the cache after update
      ref.invalidate(userPreferencesProvider(userId));
    });

// Business Settings Providers
final businessSettingsProvider = FutureProvider<BusinessSettings>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getBusinessSettings();
});

final updateBusinessSettingsProvider =
    FutureProvider.family<void, BusinessSettings>((ref, settings) async {
      final repo = ref.watch(settingsRepositoryProvider);
      await repo.updateBusinessSettings(settings);
      ref.invalidate(businessSettingsProvider);
      ref.invalidate(businessSettingsHistoryProvider);
    });

final businessSettingsHistoryProvider =
    FutureProvider.family<List<BusinessSettingsHistory>, int>((
      ref,
      limit,
    ) async {
      final repo = ref.watch(settingsRepositoryProvider);
      return repo.getSettingsHistory(limit: limit);
    });

final rollbackBusinessSettingsProvider = FutureProvider.family<void, int>((
  ref,
  version,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.rollbackSettings(version);
  ref.invalidate(businessSettingsProvider);
  ref.invalidate(businessSettingsHistoryProvider);
});

// Shipping Zones Providers
final shippingZonesProvider = FutureProvider<List<ShippingZone>>((ref) async {
  final settings = await ref.watch(businessSettingsProvider.future);
  return settings.shippingZones;
});

final addShippingZoneProvider = FutureProvider.family<void, ShippingZone>((
  ref,
  zone,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.addShippingZone(zone);
  ref.invalidate(shippingZonesProvider);
  ref.invalidate(businessSettingsProvider);
});

final updateShippingZoneProvider =
    FutureProvider.family<void, (String, ShippingZone)>((ref, params) async {
      final repo = ref.watch(settingsRepositoryProvider);
      final (zoneId, zone) = params;
      await repo.updateShippingZone(zoneId, zone);
      ref.invalidate(shippingZonesProvider);
      ref.invalidate(businessSettingsProvider);
    });

final removeShippingZoneProvider = FutureProvider.family<void, String>((
  ref,
  zoneId,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.removeShippingZone(zoneId);
  ref.invalidate(shippingZonesProvider);
  ref.invalidate(businessSettingsProvider);
});

// Payment Methods Providers
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final settings = await ref.watch(businessSettingsProvider.future);
  return settings.paymentMethods;
});

final addPaymentMethodProvider = FutureProvider.family<void, PaymentMethod>((
  ref,
  method,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.addPaymentMethod(method);
  ref.invalidate(paymentMethodsProvider);
  ref.invalidate(businessSettingsProvider);
});

final updatePaymentMethodProvider =
    FutureProvider.family<void, (String, PaymentMethod)>((ref, params) async {
      final repo = ref.watch(settingsRepositoryProvider);
      final (methodId, method) = params;
      await repo.updatePaymentMethod(methodId, method);
      ref.invalidate(paymentMethodsProvider);
      ref.invalidate(businessSettingsProvider);
    });

final removePaymentMethodProvider = FutureProvider.family<void, String>((
  ref,
  methodId,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.removePaymentMethod(methodId);
  ref.invalidate(paymentMethodsProvider);
  ref.invalidate(businessSettingsProvider);
});

final setDefaultPaymentMethodProvider = FutureProvider.family<void, String>((
  ref,
  methodId,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.setDefaultPaymentMethod(methodId);
  ref.invalidate(paymentMethodsProvider);
  ref.invalidate(businessSettingsProvider);
});

// API Settings Providers
final apiSettingsProvider = FutureProvider<APISettings>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getAPISettings();
});

final updateAPISettingsProvider = FutureProvider.family<void, APISettings>((
  ref,
  settings,
) async {
  final repo = ref.watch(settingsRepositoryProvider);
  await repo.updateAPISettings(settings);
  ref.invalidate(apiSettingsProvider);
});

final validateAPIConnectionProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, service) async {
      final repo = ref.watch(settingsRepositoryProvider);
      return repo.validateAPIConnection(service);
    });

// Theme Provider for current user
final currentUserThemeProvider =
    FutureProvider.family<ThemePreference?, String>((ref, userId) async {
      final prefs = await ref.watch(userPreferencesProvider(userId).future);
      return prefs?.theme;
    });

// Notification Settings Provider
final notificationSettingsProvider =
    FutureProvider.family<Map<String, bool>, String>((ref, userId) async {
      final prefs = await ref.watch(userPreferencesProvider(userId).future);
      return {
        'notifications': prefs?.enableNotifications ?? true,
        'email_notifications': prefs?.enableEmailNotifications ?? true,
        'push_notifications': prefs?.enablePushNotifications ?? true,
        'in_app_notifications': prefs?.enableInAppNotifications ?? true,
      };
    });

// Favorite Modules Provider
final favoriteModulesProvider = FutureProvider.family<List<String>, String>((
  ref,
  userId,
) async {
  final prefs = await ref.watch(userPreferencesProvider(userId).future);
  return prefs?.favoriteModules ?? [];
});

final addFavoriteModuleProvider = FutureProvider.family<void, (String, String)>(
  (ref, params) async {
    final repo = ref.watch(settingsRepositoryProvider);
    final (userId, moduleName) = params;
    await repo.addFavoriteModule(userId, moduleName);
    ref.invalidate(favoriteModulesProvider(userId));
    ref.invalidate(userPreferencesProvider(userId));
  },
);

final removeFavoriteModuleProvider =
    FutureProvider.family<void, (String, String)>((ref, params) async {
      final repo = ref.watch(settingsRepositoryProvider);
      final (userId, moduleName) = params;
      await repo.removeFavoriteModule(userId, moduleName);
      ref.invalidate(favoriteModulesProvider(userId));
      ref.invalidate(userPreferencesProvider(userId));
    });

// Tax Settings Provider
final taxSettingsProvider = FutureProvider<(String?, double?)>((ref) async {
  final settings = await ref.watch(businessSettingsProvider.future);
  return (settings.taxId, settings.taxRate);
});

// Currency Provider
final currencyProvider = FutureProvider<String?>((ref) async {
  final settings = await ref.watch(businessSettingsProvider.future);
  return settings.currency;
});

// Sidebar Collapsed State Provider
final sidebarCollapsedProvider = FutureProvider.family<bool, String>((
  ref,
  userId,
) async {
  final prefs = await ref.watch(userPreferencesProvider(userId).future);
  return prefs?.sidebarCollapsed ?? false;
});
