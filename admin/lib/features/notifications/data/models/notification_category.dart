import 'package:flutter/material.dart';

enum NotificationCategory {
  sales,
  orders,
  order,
  reviews,
  users,
  inventory,
  system,
  billing,
  shipping;

  String get displayName {
    switch (this) {
      case NotificationCategory.sales:
        return 'Sales';
      case NotificationCategory.orders:
        return 'Orders';
      case NotificationCategory.order:
        return 'Order';
      case NotificationCategory.reviews:
        return 'Reviews';
      case NotificationCategory.users:
        return 'Users';
      case NotificationCategory.inventory:
        return 'Inventory';
      case NotificationCategory.system:
        return 'System';
      case NotificationCategory.billing:
        return 'Billing';
      case NotificationCategory.shipping:
        return 'Shipping';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.sales:
        return Icons.trending_up;
      case NotificationCategory.orders:
        return Icons.shopping_cart;
      case NotificationCategory.order:
        return Icons.shopping_bag;
      case NotificationCategory.reviews:
        return Icons.star;
      case NotificationCategory.users:
        return Icons.people;
      case NotificationCategory.inventory:
        return Icons.inventory;
      case NotificationCategory.system:
        return Icons.settings;
      case NotificationCategory.billing:
        return Icons.receipt;
      case NotificationCategory.shipping:
        return Icons.local_shipping;
    }
  }
}
