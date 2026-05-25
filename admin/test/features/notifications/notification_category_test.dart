import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_category.dart';

void main() {
  group('NotificationCategory', () {
    test('has correct display names', () {
      expect(NotificationCategory.sales.displayName, 'Sales');
      expect(NotificationCategory.orders.displayName, 'Orders');
      expect(NotificationCategory.reviews.displayName, 'Reviews');
      expect(NotificationCategory.users.displayName, 'Users');
      expect(NotificationCategory.inventory.displayName, 'Inventory');
      expect(NotificationCategory.system.displayName, 'System');
    });

    test('has correct icons', () {
      expect(NotificationCategory.sales.icon, Icons.trending_up);
      expect(NotificationCategory.orders.icon, Icons.shopping_cart);
      expect(NotificationCategory.reviews.icon, Icons.star);
      expect(NotificationCategory.users.icon, Icons.people);
      expect(NotificationCategory.inventory.icon, Icons.inventory);
      expect(NotificationCategory.system.icon, Icons.settings);
    });

    test('has all expected values', () {
      expect(NotificationCategory.values.length, 6);
      expect(
        NotificationCategory.values,
        containsAll([
          NotificationCategory.sales,
          NotificationCategory.orders,
          NotificationCategory.reviews,
          NotificationCategory.users,
          NotificationCategory.inventory,
          NotificationCategory.system,
        ]),
      );
    });

    test('displayName returns correct value for each category', () {
      for (final category in NotificationCategory.values) {
        expect(category.displayName, isNotEmpty);
      }
    });

    test('icon returns valid IconData for each category', () {
      for (final category in NotificationCategory.values) {
        expect(category.icon, isA<IconData>());
      }
    });
  });
}
