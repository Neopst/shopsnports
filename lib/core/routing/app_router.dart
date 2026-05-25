import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/screens/splash_screen.dart';
import 'package:shopsnports/screens/splash/animated_splash_screen.dart';
import 'package:shopsnports/screens/onboarding/stylish_onboarding_screen.dart';
import 'package:shopsnports/screens/navigation_shell.dart';
import 'package:shopsnports/screens/request_shipping_screen.dart';
import 'package:shopsnports/screens/onboarding/role_selection_screen.dart';
import 'package:shopsnports/screens/landing_page_screen.dart';
import 'package:shopsnports/screens/shipping/shipping_request_screen.dart';
import 'package:shopsnports/screens/shipping/shipping_request_form_screen.dart';
import 'package:shopsnports/screens/shipping/track_shipment_screen.dart';
import 'package:shopsnports/screens/shipping/tracking_lookup_screen.dart';
import 'package:shopsnports/screens/shipping/shipping_history_screen.dart';
import 'package:shopsnports/screens/shipping/quote_request_screen.dart';
import 'package:shopsnports/screens/shipping/pickup_scheduling_screen.dart';
import 'package:shopsnports/screens/settings/user_settings_screen.dart';
import 'package:shopsnports/screens/alerts/alerts_notifications_screen.dart';
import 'package:shopsnports/screens/notifications_screen.dart';
import 'package:shopsnports/screens/admin/admin_dashboard_screen.dart';
import 'package:shopsnports/screens/shipments/shipment_detail_screen.dart';
import 'package:shopsnports/screens/shipments/shipments_list_screen.dart';
// Removed vendor/profile_screen.dart (shopping logic)
// Removed vendor_dashboard_screen.dart (shopping logic)
// Removed vendor_products_screen.dart (shopping logic)
// Removed vendor/product_management_screen.dart (shopping logic)
import 'package:shopsnports/screens/affiliate/affiliate_dashboard_screen.dart';
import 'package:shopsnports/screens/affiliate/profile_screen.dart' as affiliate;
import 'package:shopsnports/screens/auth/affiliate_registration_screen.dart';
import 'package:shopsnports/screens/affiliate_pending_screen.dart';
import 'package:shopsnports/screens/affiliate_join_screen.dart';
import 'package:shopsnports/screens/auth/affiliate_introduction_screen.dart';
import 'package:shopsnports/screens/affiliate/payouts_screen.dart';
import 'package:shopsnports/screens/affiliate/commission_tracking_screen.dart';
import 'package:shopsnports/screens/affiliate/payout_management_screen.dart';
import 'package:shopsnports/screens/affiliate/form_shares_screen.dart';
// Removed product_details_screen.dart (shopping logic)
import 'package:shopsnports/screens/phone_login_screen.dart';
import 'package:shopsnports/screens/auth/stylish_login_screen.dart';
import 'package:shopsnports/screens/auth/unified_signup_screen.dart';
import 'package:shopsnports/screens/add_address_screen.dart';
import 'package:shopsnports/screens/shipper/shipper_dashboard_screen.dart';
import 'package:shopsnports/screens/customer/customer_home_screen.dart';
import 'package:shopsnports/screens/public/shipment_request_form.dart';
import 'package:shopsnports/screens/help_center_screen.dart';
import 'package:shopsnports/screens/settings_screen.dart';
import 'package:shopsnports/screens/profile/edit_profile_screen.dart';
import 'package:shopsnports/screens/profile/profile_screen.dart';
import 'package:shopsnports/screens/customer/invoices_screen.dart';
import 'package:shopsnports/screens/customer/invoice_detail_screen.dart';
// Removed customer/my_reviews_screen.dart (shopping logic)
// Removed customer/write_review_screen.dart (shopping logic)
// Removed cart_screen.dart (shopping logic)
// Removed cart/checkout_screen.dart (shopping logic)
// Removed cart/payment_methods_screen.dart (shopping logic)
// Removed orders/order_details_screen.dart (shopping logic)
// Removed track_order_screen.dart (deleted - shopping logic)
// Removed product/product_list_screen.dart (shopping logic)
// Removed category_products_screen.dart (shopping logic)
import 'package:shopsnports/screens/help/faq_contact_screen.dart';
import 'package:shopsnports/screens/legal/terms_of_service_screen.dart';
import 'package:shopsnports/screens/legal/privacy_policy_screen.dart';
import 'package:shopsnports/widgets/shipper_gate.dart';
import 'package:shopsnports/utils/app_logger.dart';

/// Centralized route generator for the entire app
class AppRouter {
  // Prevent instantiation
  AppRouter._();

  /// Generate route based on route settings
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    AppLogger.navigation(
      settings.name ?? 'unknown',
      settings.arguments as Map<String, dynamic>?,
    );

    switch (settings.name) {
      // Core routes
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen());

      case AppRoutes.animatedSplash:
        return _buildRoute(const AnimatedSplashScreen());

      case AppRoutes.onboarding:
        return _buildRoute(const StylishOnboardingScreen());

      case AppRoutes.roleSelection:
        return _buildRoute(const RoleSelectionScreen());

      case AppRoutes.landing:
        return _buildRoute(const LandingPageScreen());

      case AppRoutes.home:
        return _buildRoute(const NavigationShell(initialIndex: 0));

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen());

      case AppRoutes.help:
        return _buildRoute(const HelpCenterScreen());

      case AppRoutes.editProfile:
        return _buildRoute(const EditProfileScreen());

      case AppRoutes.addAddress:
        return _buildRoute(const AddAddressScreen());

      // Auth routes
      case AppRoutes.login:
        return _buildRoute(const StylishLoginScreen());

      case AppRoutes.signup:
        // Get role from arguments if provided (from role selection screen)
        final signupArgs = settings.arguments as Map<String, dynamic>?;
        final role = signupArgs?['role'];
        return _buildRoute(
          UnifiedSignupScreen(
            initialRole: role,
          ),
        );

      case AppRoutes.phoneLogin:
        return _buildRoute(const PhoneLoginScreen());

      // Affiliate routes
      case AppRoutes.affiliateDashboard:
        return _buildRoute(const _AffiliateRouteGuard());

      case AppRoutes.affiliateProfile:
        return _buildRoute(const affiliate.AffiliateProfileScreen());

      case AppRoutes.affiliateRegister:
        return _buildRoute(const AffiliateRegistrationScreen());

      case AppRoutes.affiliateJoin:
        return _buildRoute(const AffiliateJoinScreen());

      case AppRoutes.affiliateIntro:
        final args = settings.arguments as Map<String, dynamic>?;
        final referralCode = args?['referralCode'] as String?;
        return _buildRoute(AffiliateIntroductionScreen(referralCode: referralCode));

      case AppRoutes.affiliateCommissionTracking:
        return _buildRoute(const CommissionTrackingScreen());

      case AppRoutes.affiliatePayoutManagement:
        return _buildRoute(const PayoutManagementScreen());

      case AppRoutes.affiliatePayouts:
        final args = settings.arguments as Map<String, dynamic>?;
        final affiliateId = args?['affiliateId'] as String? ?? 'aff-debug';
        return _buildRoute(
          AffiliatePayoutsScreen(affiliateId: affiliateId),
        );

      case AppRoutes.affiliateFormShares:
        final args = settings.arguments as Map<String, dynamic>?;
        final affiliateId = args?['affiliateId'] as String? ?? '';
        return _buildRoute(
          FormSharesScreen(affiliateId: affiliateId),
        );

      // Admin functionality moved to web dashboard only
      // Access admin panel at: https://admin.shopsnports.com (Firebase Hosting)

      // Shipper routes
      case AppRoutes.shipperDashboard:
        return _buildRoute(
          const ShipperGate(child: ShipperDashboardScreen()),
        );

      case AppRoutes.shipperVerify:
        return _buildRoute(
          const RequestShippingScreen(asShipperVerification: true),
        );

      case AppRoutes.requestShipping:
        // Use the new Firestore-backed shipping form instead of the
        // legacy dummy screen. Arguments may supply an affiliateId if
        // the caller already knows it (e.g. affiliate dashboard). The
        // form itself will also fallback to the current user's
        // affiliateId when submitting.
        final args = settings.arguments as Map<String, dynamic>?;
        final affiliateId = args?['affiliateId'] as String?;
        return _buildRoute(ShippingRequestFormScreen(
          affiliateId: affiliateId,
        ));

      case AppRoutes.shipments:
        // a simple route pointing to the shipments list screen
        return _buildRoute(const ShipmentsListScreen());

      case AppRoutes.shippingRequest:
        return _buildRoute(const ShippingRequestScreen());

      case AppRoutes.shippingForm:
        final args = settings.arguments as Map<String, dynamic>?;
        final affiliateId = args?['affiliateId'] as String?;
        return _buildRoute(
          ShippingRequestFormScreen(affiliateId: affiliateId),
        );

      case AppRoutes.trackShipment:
        final trackArgs = settings.arguments as Map<String, dynamic>?;
        final trackingNumber = trackArgs?['tracking'] as String?;
        final requestId = trackArgs?['requestId'] as String?;

        // If tracking number provided, use new Firestore-based lookup
        if (trackingNumber != null) {
          return _buildRoute(
              TrackingLookupScreen(trackingNumber: trackingNumber));
        }

        // Otherwise fall back to old request ID lookup
        if (requestId != null) {
          return _buildRoute(TrackShipmentScreen(requestId: requestId));
        }

        // Default: show lookup screen without pre-populated tracking
        return _buildRoute(const TrackingLookupScreen());

      case AppRoutes.shipmentDetail:
        final shipmentId = settings.arguments as String?;
        if (shipmentId == null) {
          return _buildRoute(
            Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Shipment ID required')),
            ),
          );
        }
        return _buildRoute(ShipmentDetailScreen(shipmentId: shipmentId));

      case AppRoutes.quoteRequest:
        return _buildRoute(const QuoteRequestScreen());

      case AppRoutes.pickupScheduling:
        final pickupArgs = settings.arguments as Map<String, dynamic>?;
        final shipmentId = pickupArgs?['shipmentId'] as String?;
        return _buildRoute(PickupSchedulingScreen(shipmentId: shipmentId));

      case AppRoutes.userSettings:
        return _buildRoute(const UserSettingsScreen());

      case AppRoutes.alertsNotifications:
        return _buildRoute(const AlertsNotificationsScreen());

      case AppRoutes.notifications:
        return _buildRoute(const NotificationsScreen());

      case AppRoutes.shippingHistory:
        return _buildRoute(const ShippingHistoryScreen());

      case AppRoutes.adminDashboard:
        return _buildRoute(const AdminDashboardScreen());

      // Customer routes
      case AppRoutes.customerHome:
        return _buildRoute(const CustomerHomeScreen());

      case AppRoutes.profile:
        return _buildRoute(const ProfileScreen());

      // Customer invoice routes
      case AppRoutes.invoices:
        return _buildRoute(const InvoicesScreen());

      case AppRoutes.invoiceDetail:
        final invoiceId = settings.arguments as String?;
        if (invoiceId == null) {
          return _buildRoute(
            Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Invoice ID required')),
            ),
          );
        }
        return _buildRoute(InvoiceDetailScreen(invoiceId: invoiceId));

      // Help and Support routes
      case AppRoutes.faq:
        return _buildRoute(const FaqContactScreen());

      case AppRoutes.contactSupport:
        return _buildRoute(const FaqContactScreen());

      // Legal routes
      case AppRoutes.termsOfService:
        return _buildRoute(const TermsOfServiceScreen());

      case AppRoutes.privacyPolicy:
        return _buildRoute(const PrivacyPolicyScreen());

      // Public routes
      case AppRoutes.publicShipmentRequest:
        final args = settings.arguments as Map<String, dynamic>?;
        final token = args?['token'] as String?;
        if (token == null) {
          return _buildRoute(
            const Scaffold(
              body: Center(child: Text('Invalid token')),
            ),
          );
        }
        return _buildRoute(ShipmentRequestFormScreen(token: token));

      // Unknown route
      default:
        AppLogger.error('Unknown route: ${settings.name}');
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }

  /// Build a standard MaterialPageRoute
  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}

/// Route guard for affiliate dashboard - requires authentication and affiliate approval
class _AffiliateRouteGuard extends ConsumerWidget {
  const _AffiliateRouteGuard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      AppLogger.debug('Affiliate route guard: User not authenticated');
      return Scaffold(
        appBar: AppBar(title: const Text('Affiliate Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please sign in to access the affiliate dashboard',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.login),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    if (user.affiliateApproved == true) {
      return const AffiliateDashboardScreen();
    }

    return const AffiliatePendingScreen();
  }
}
