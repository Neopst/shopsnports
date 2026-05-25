// FILE: lib/core/routing/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the DashboardShell class
import 'package:admin_dashboard/features/dashboard/presentation/dashboard_shell.dart';
// ADD THIS IMPORT
import '../../features/orders/presentation/orders_screen.dart';
// Screens
import 'package:admin_dashboard/features/auth/presentation/login_screen.dart';
import 'package:admin_dashboard/features/dashboard/presentation/overview_screen.dart';
import 'package:admin_dashboard/features/dashboard/presentation/customers_screen.dart';
// REMOVE OLD REVIEWS IMPORT: import 'package:admin_dashboard/features/dashboard/presentation/reviews_screen.dart';
import 'package:admin_dashboard/features/dashboard/presentation/affiliates_screen.dart';
// Use the new invoices screens
import 'package:admin_dashboard/features/invoices/presentation/screens/invoices_list_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_form_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/public_invoice_view_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_reminders_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_exports_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_reconciliation_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/tax_calculation_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_templates_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_line_items_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_notes_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_history_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_number_customizations_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_currencies_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_discounts_screen.dart';
import 'package:admin_dashboard/features/invoices/presentation/screens/invoice_credit_notes_screen.dart';
// Use the new notifications list screen
import 'package:admin_dashboard/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/user_notification_preferences_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_history_screen.dart' as notif;
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_templates_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_template_versions_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_batches_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/user_segments_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_ab_tests_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_analytics_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/scheduled_notifications_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_retry_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_sounds_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_badges_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_deep_links_screen.dart';
import 'package:admin_dashboard/features/notifications/presentation/screens/notification_localizations_screen.dart';
// Push Notifications
import 'package:admin_dashboard/features/push_notifications/presentation/screens/send_notification_screen.dart';
import 'package:admin_dashboard/features/push_notifications/presentation/screens/notification_history_screen.dart' as push;
// Import new dashboard screens
import 'package:admin_dashboard/features/content/presentation/screens/content_dashboard_screen.dart';
import 'package:admin_dashboard/features/settings/presentation/screens/settings_dashboard_screen.dart';
import 'package:admin_dashboard/features/dashboard/presentation/configuration_screen.dart';

// Shipping Management Screen
import 'package:admin_dashboard/features/shipping/presentation/screens/shipping_list_screen.dart';
import 'package:admin_dashboard/features/shipping/presentation/screens/shipping_detail_screen.dart';

// Super Admin Screens - NEW Firestore-based implementation
import 'package:admin_dashboard/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import 'package:admin_dashboard/features/super_admin/presentation/screens/admin_profile_screen.dart';
import 'package:admin_dashboard/features/super_admin/presentation/screens/manage_admins_screen.dart';
import 'package:admin_dashboard/features/super_admin/presentation/screens/create_admin_screen.dart';
import 'package:admin_dashboard/features/super_admin/presentation/screens/admin_activity_logs_screen.dart';
import 'package:admin_dashboard/features/super_admin/presentation/screens/super_admin_my_profile_screen.dart';

// News Ticker Screen
import 'package:admin_dashboard/features/news_ticker/presentation/screens/news_ticker_screen.dart';

// Auth Screens
import 'package:admin_dashboard/features/auth/presentation/screens/user_profile_screen.dart';

// Payouts Screens
import 'package:admin_dashboard/features/payouts/presentation/screens/enhanced_payouts_dashboard.dart';
import 'package:admin_dashboard/features/payouts/presentation/screens/payouts_settings_screen.dart';

// Analytics Screens
import 'package:admin_dashboard/features/analytics/presentation/screens/enhanced_analytics_dashboard.dart';

// Router configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),

      // Public invoice view (no authentication required)
      GoRoute(
        path: '/invoice/:accessToken',
        builder: (context, state) {
          final accessToken = state.pathParameters['accessToken']!;
          return PublicInvoiceViewScreen(accessToken: accessToken);
        },
      ),

      // Add to your routes
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),

      // Dashboard routes
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(location: state.uri.toString(), child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard/overview',
            builder: (c, s) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/dashboard/customers',
            builder: (c, s) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/dashboard/orders',
            builder: (c, s) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/dashboard/shipping-request',
            builder: (c, s) => const AdminShippingListScreen(),
          ),
          // Shipping Request Management Route - Individual Shipping Request
          GoRoute(
            path: '/admin/shipping/:requestId',
            builder: (c, s) {
              final requestId = s.pathParameters['requestId']!;
              return AdminShippingDetailScreen(requestId: requestId);
            },
          ),
          GoRoute(
            path: '/dashboard/affiliates',
            builder: (c, s) => const AffiliatesScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices',
            builder: (c, s) => const InvoicesListScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/create',
            builder: (c, s) => const InvoiceFormScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/:id',
            builder: (c, s) {
              final id = s.pathParameters['id']!;
              return InvoiceDetailScreen(invoiceId: id);
            },
          ),
          GoRoute(
            path: '/dashboard/invoices/:id/edit',
            builder: (c, s) {
              final id = s.pathParameters['id']!;
              return InvoiceFormScreen(invoiceId: id);
            },
          ),
          GoRoute(
            path: '/dashboard/invoices/reminders',
            builder: (c, s) => const InvoiceRemindersScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/exports',
            builder: (c, s) => const InvoiceExportsScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/reconciliation',
            builder: (c, s) => const InvoiceReconciliationScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/tax-calculation',
            builder: (c, s) => const TaxCalculationScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/templates',
            builder: (c, s) => const InvoiceTemplatesScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/line-items',
            builder: (c, s) => const InvoiceLineItemsScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/notes',
            builder: (c, s) => const InvoiceNotesScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/history',
            builder: (c, s) => const InvoiceHistoryScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/number-customizations',
            builder: (c, s) => const InvoiceNumberCustomizationsScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/currencies',
            builder: (c, s) => const InvoiceCurrenciesScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/discounts',
            builder: (c, s) => const InvoiceDiscountsScreen(),
          ),
          GoRoute(
            path: '/dashboard/invoices/credit-notes',
            builder: (c, s) => const InvoiceCreditNotesScreen(),
          ),
          GoRoute(
            path: '/dashboard/content',
            builder: (c, s) => const ContentDashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/settings',
            builder: (c, s) => const SettingsDashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/configuration',
            builder: (c, s) => const ConfigurationScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications',
            builder: (c, s) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/preferences',
            builder: (c, s) => const UserNotificationPreferencesScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/history',
            builder: (c, s) => const notif.NotificationHistoryScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/templates',
            builder: (c, s) => const NotificationTemplatesScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/templates/:templateId/versions',
            builder: (c, s) {
              final templateId = s.pathParameters['templateId']!;
              return NotificationTemplateVersionsScreen(templateId: templateId);
            },
          ),
          GoRoute(
            path: '/dashboard/notifications/analytics',
            builder: (c, s) => const NotificationAnalyticsScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/scheduled',
            builder: (c, s) => const ScheduledNotificationsScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/retry',
            builder: (c, s) => const NotificationRetryScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/batches',
            builder: (c, s) => const NotificationBatchesScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/segments',
            builder: (c, s) => const UserSegmentsScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/ab-tests',
            builder: (c, s) => const NotificationABTestsScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/sounds',
            builder: (c, s) => const NotificationSoundsScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/badges',
            builder: (c, s) => const NotificationBadgesScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/deep-links',
            builder: (c, s) => const NotificationDeepLinksScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications/localizations',
            builder: (c, s) => const NotificationLocalizationsScreen(),
          ),
          GoRoute(
            path: '/dashboard/push-notifications',
            builder: (c, s) => const SendNotificationScreen(),
          ),
          GoRoute(
            path: '/dashboard/push-notifications/history',
            builder: (c, s) => const push.NotificationHistoryScreen(),
          ),
          // Super Admin Routes - NEW Firestore-based implementation
          GoRoute(
            path: '/dashboard/super-admin',
            builder: (c, s) => const SuperAdminDashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/super-admin/my-profile',
            builder: (c, s) => const SuperAdminMyProfileScreen(),
          ),
          GoRoute(
            path: '/dashboard/super-admin/profile/:adminId',
            builder: (c, s) {
              final adminId = s.pathParameters['adminId']!;
              return AdminProfileScreen(adminId: adminId);
            },
          ),
          GoRoute(
            path: '/dashboard/super-admin/manage',
            builder: (c, s) => const ManageAdminsScreen(),
          ),
          GoRoute(
            path: '/dashboard/super-admin/create',
            builder: (c, s) => const CreateAdminScreen(),
          ),
          GoRoute(
            path: '/dashboard/super-admin/logs',
            builder: (c, s) => const AdminActivityLogsScreen(),
          ),
          GoRoute(
            path: '/dashboard/news-ticker',
            builder: (c, s) => const NewsTickerScreen(),
          ),
          GoRoute(
            path: '/dashboard/payouts',
            builder: (c, s) {
              final affiliateId = s.uri.queryParameters['affiliateId'];
              return EnhancedPayoutsDashboard(affiliateId: affiliateId);
            },
          ),
          GoRoute(
            path: '/dashboard/payouts-settings',
            builder: (c, s) => const PayoutsSettingsScreen(),
          ),
          GoRoute(
            path: '/dashboard/analytics',
            builder: (c, s) => const EnhancedAnalyticsDashboard(),
          ),
        ],
      ),
    ],
  );
});

// Legacy export for backwards compatibility
final appRouter = GoRouter(initialLocation: '/', routes: []);
