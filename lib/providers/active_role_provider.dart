import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsnports/providers/user_providers.dart';

/// Available user roles in the app for role switching
/// Note: Shipper is not included - it's part of customer journey, not a separate mode
enum UserRole {
  customer('customer', 'Customer', '🏪'),
  affiliate('affiliate', 'Affiliate', '🤝');

  const UserRole(this.value, this.label, this.icon);
  final String value;
  final String label;
  final String icon;
}

/// Active role notifier - manages current user role selection
class ActiveRoleNotifier extends StateNotifier<String> {
  ActiveRoleNotifier() : super('shop') {
    _loadActiveRole();
  }

  static const _storageKey = 'active_role';

  /// Load persisted active role from SharedPreferences
  Future<void> _loadActiveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString(_storageKey);
      if (savedRole != null && savedRole.isNotEmpty) {
        state = savedRole;
      }
    } catch (_) {
      // Ignore errors, keep default 'shop'
    }
  }

  /// Set active role and persist to storage
  Future<void> setRole(String role) async {
    state = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, role);
    } catch (_) {
      // Ignore storage errors
    }
  }

  /// Reset to default 'shop' role
  Future<void> reset() async {
    await setRole('shop');
  }
}

/// Provider for active role state
final activeRoleProvider =
    StateNotifierProvider<ActiveRoleNotifier, String>((ref) {
  return ActiveRoleNotifier();
});

/// Provider that computes available roles for current user
/// Only includes roles that need switching (vendor, affiliate)
/// Customer/Shipper don't need role switching - they're base functionality
final availableRolesProvider = Provider<List<UserRole>>((ref) {
  final user = ref.watch(currentUserProvider);
  final roles = <UserRole>[UserRole.customer]; // Customer mode (everyone)

  if (user != null) {
    // Only add business roles that need mode switching
    if (user.isAffiliate == true) {
      roles.add(UserRole.affiliate);
    }
    // Note: Shipper not included - shipping is part of customer journey
  }

  return roles;
});

/// Provider that gets route for a given role
final roleRouteProvider = Provider.family<String, String>((ref, role) {
  switch (role) {
    case 'affiliate':
      return '/affiliate/dashboard';
    case 'customer':
    default:
      return '/home';
  }
});

/// Provider that determines initial route after login based on user roles
final initialRouteAfterLoginProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) return '/home';

  // Priority: Admin > Affiliate > Customer
  if (user.isAdmin == true) return '/admin/mini';
  if (user.isAffiliate == true) return '/affiliate/dashboard';

  return '/home';
});
