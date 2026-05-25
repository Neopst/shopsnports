import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_type.dart';

void main() {
  group('NotificationType', () {
    test('has correct display names', () {
      expect(NotificationType.orderStatus.displayName, 'Order Status');
      expect(NotificationType.payment.displayName, 'Payment');
      expect(NotificationType.review.displayName, 'Review');
      expect(NotificationType.userActivity.displayName, 'User Activity');
      expect(NotificationType.inventory.displayName, 'Inventory');
      expect(NotificationType.system.displayName, 'System');
      expect(NotificationType.message.displayName, 'Message');
    });

    test('has correct icons', () {
      expect(NotificationType.orderStatus.icon, '📦');
      expect(NotificationType.payment.icon, '💰');
      expect(NotificationType.review.icon, '⭐');
      expect(NotificationType.userActivity.icon, '👤');
      expect(NotificationType.inventory.icon, '📊');
      expect(NotificationType.system.icon, '⚙️');
      expect(NotificationType.message.icon, '💬');
    });

    test('has all expected values', () {
      expect(NotificationType.values.length, 7);
      expect(
        NotificationType.values,
        containsAll([
          NotificationType.orderStatus,
          NotificationType.payment,
          NotificationType.review,
          NotificationType.userActivity,
          NotificationType.inventory,
          NotificationType.system,
          NotificationType.message,
        ]),
      );
    });

    test('displayName returns correct value for each type', () {
      for (final type in NotificationType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });
  });
}
