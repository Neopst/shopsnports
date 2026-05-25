/// Centralized route name constants for type-safe navigation
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Core routes
  static const String splash = '/splash';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String addAddress = '/add-address';
  static const String editProfile = '/profile/edit';

  // Onboarding routes
  static const String landing = '/landing';
  static const String roleSelection = '/role-selection';
  static const String onboarding = '/onboarding';
  static const String animatedSplash = '/animated-splash';

  // Auth routes
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String phoneLogin = '/auth/phone';

  // Affiliate routes (Shipping context - affiliate agents/shippers)
  static const String affiliateDashboard = '/affiliate/dashboard';
  static const String affiliateProfile = '/affiliate/profile';
  static const String affiliateRegister = '/auth/affiliate_register';
  static const String affiliateJoin = '/affiliate/join';
  static const String affiliateIntro = '/affiliate/intro';
  static const String affiliatePayouts = '/affiliate/payouts';
  static const String affiliateCommissionTracking =
      '/affiliate/commission-tracking';
  static const String affiliatePayoutManagement =
      '/affiliate/payout-management';
  static const String affiliateFormShares = '/affiliate/form-shares';

  // Shipper routes
  static const String shipperDashboard = '/shipper/dashboard';
  static const String shipperVerify = '/verify/shipper';
  static const String requestShipping = '/request-shipping';
  static const String shippingRequest = '/shipping/request';
  static const String shippingForm = '/shipping/form';
  static const String trackShipment = '/shipping/track';
  static const String shipmentDetail = '/shipment-detail';

  // Shortcuts
  static const String shipments = '/shipments';

  // Quote & Pickup routes
  static const String quoteRequest = '/quote-request';
  static const String pickupScheduling = '/pickup-scheduling';

  // User settings & Alerts routes
  static const String userSettings = '/user-settings';
  static const String alertsNotifications = '/alerts-notifications';
  static const String notifications = '/notifications';
  static const String shippingHistory = '/shipping-history';
  static const String adminDashboard = '/admin/dashboard';

  // Customer routes (Shipping context - guest & registered customers)
  static const String customerHome = '/customer/home';
  static const String profile = '/profile';
  static const String invoices = '/customer/invoices';
  static const String invoiceDetail = '/customer/invoice-detail';

  // Help & Legal
  static const String faq = '/help/faq';
  static const String contactSupport = '/help/contact';

  // Legal
  static const String termsOfService = '/legal/terms';
  static const String privacyPolicy = '/legal/privacy';

  // Public routes
  static const String publicShipmentRequest = '/public/shipment-request';
}
