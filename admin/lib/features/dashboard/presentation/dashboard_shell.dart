// FILE: lib/features/dashboard/presentation/dashboard_shell.dart
import 'package:flutter/material.dart';
import 'widgets/sidebar_navigation.dart';
import 'widgets/top_app_bar.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final String location;

  const DashboardShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation - ALWAYS VISIBLE
          SidebarNavigation(currentRoute: location),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                TopAppBar(
                  title: _getTitleFromRoute(location),
                  showBackButton: _shouldShowBackButton(location),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitleFromRoute(String route) {
    switch (route) {
      case '/dashboard/overview':
        return 'Dashboard Overview';
      case '/dashboard/customers':
        return 'Customer Management';
      case '/dashboard/orders':
        return 'Order Management';
      case '/dashboard/shipping-request':
        return 'Shipping Requests';
      case '/dashboard/affiliates':
        return 'Affiliate Management';
      case '/dashboard/invoices':
        return 'Invoice Management';
      case '/dashboard/payouts':
        return 'Payouts Management';
      case '/dashboard/analytics':
        return 'Analytics Dashboard';
      case '/dashboard/notifications':
        return 'Notifications';
      case '/dashboard/content':
        return 'Content Management';
      case '/dashboard/settings':
        return 'Settings';
      case '/dashboard/configuration':
        return 'Configuration';
      default:
        return 'Admin Dashboard';
    }
  }

  bool _shouldShowBackButton(String route) {
    return false;
  }
}
