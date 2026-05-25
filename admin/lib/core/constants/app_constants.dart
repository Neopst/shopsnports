import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'ShopsNports Admin';
  static const String appVersion = '1.0.0';

  // Navigation items - using final instead of const
  static final List<Map<String, dynamic>> navItems = [
    {
      'title': 'Overview',
      'icon': Icons.dashboard,
      'route': '/dashboard/overview',
    },
    {
      'title': 'Shippers',
      'icon': Icons.people,
      'route': '/dashboard/customers',
    },
    {
      'title': 'Shipping Requests',
      'icon': Icons.local_shipping,
      'route': '/dashboard/orders',
    },
    {
      'title': 'Affiliates',
      'icon': Icons.attach_money,
      'route': '/dashboard/affiliates',
    },
    {
      'title': 'Invoices',
      'icon': Icons.description,
      'route': '/dashboard/invoices',
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications,
      'route': '/dashboard/notifications',
    },
    {
      'title': 'Content',
      'icon': Icons.content_copy,
      'route': '/dashboard/content',
    },
    {
      'title': 'Settings',
      'icon': Icons.settings,
      'route': '/dashboard/settings',
    },
    {
      'title': 'Configuration',
      'icon': Icons.tune,
      'route': '/dashboard/configuration',
    },
  ];
}
