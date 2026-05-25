import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_model.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_type.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_category.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_priority.dart';

void main() {
  group('Notification Model', () {
    test('creates notification with required fields', () {
      final notification = Notification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.system,
        category: NotificationCategory.system,
        title: 'Test Title',
        message: 'Test Message',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(notification.id, 'notif-1');
      expect(notification.userId, 'user-1');
      expect(notification.type, NotificationType.system);
      expect(notification.category, NotificationCategory.system);
      expect(notification.title, 'Test Title');
      expect(notification.message, 'Test Message');
      expect(notification.isRead, false);
      expect(notification.priority, NotificationPriority.normal);
    });

    test('creates notification with all fields', () {
      final metadata = {'key': 'value'};
      final readAt = DateTime(2024, 1, 2);
      final createdAt = DateTime(2024, 1, 1);

      final notification = Notification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.orderStatus,
        category: NotificationCategory.orders,
        title: 'Order Shipped',
        message: 'Your order has been shipped',
        actionUrl: '/orders/123',
        isRead: true,
        readAt: readAt,
        metadata: metadata,
        priority: NotificationPriority.high,
        createdAt: createdAt,
        updatedAt: DateTime(2024, 1, 3),
      );

      expect(notification.isRead, true);
      expect(notification.readAt, readAt);
      expect(notification.actionUrl, '/orders/123');
      expect(notification.metadata, metadata);
      expect(notification.priority, NotificationPriority.high);
      expect(notification.updatedAt, DateTime(2024, 1, 3));
    });

    test('toMap serializes correctly', () {
      final createdAt = DateTime(2024, 1, 1);
      final notification = Notification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.payment,
        category: NotificationCategory.sales,
        title: 'Payment Received',
        message: 'Your payment of \$100 was received',
        priority: NotificationPriority.critical,
        createdAt: createdAt,
      );

      final map = notification.toMap();

      expect(map['id'], 'notif-1');
      expect(map['userId'], 'user-1');
      expect(map['type'], 'payment');
      expect(map['category'], 'sales');
      expect(map['title'], 'Payment Received');
      expect(map['message'], 'Your payment of \$100 was received');
      expect(map['priority'], 'critical');
      expect(map['isRead'], false);
      expect(map['actionUrl'], null);
      expect(map['metadata'], null);
    });

    test('fromMap deserializes correctly', () {
      final createdAt = Timestamp.fromDate(DateTime(2024, 1, 1));
      final map = {
        'id': 'notif-2',
        'userId': 'user-2',
        'type': 'review',
        'category': 'reviews',
        'title': 'New Review',
        'message': 'You received a 5-star review',
        'actionUrl': '/reviews/456',
        'isRead': true,
        'readAt': null,
        'metadata': {'rating': 5},
        'priority': 'high',
        'createdAt': createdAt,
        'updatedAt': null,
      };

      final notification = Notification.fromMap(map);

      expect(notification.id, 'notif-2');
      expect(notification.userId, 'user-2');
      expect(notification.type, NotificationType.review);
      expect(notification.category, NotificationCategory.reviews);
      expect(notification.title, 'New Review');
      expect(notification.message, 'You received a 5-star review');
      expect(notification.actionUrl, '/reviews/456');
      expect(notification.isRead, true);
      expect(notification.metadata, {'rating': 5});
      expect(notification.priority, NotificationPriority.high);
    });

    test('fromMap handles unknown type and category with defaults', () {
      final createdAt = Timestamp.fromDate(DateTime(2024, 1, 1));
      final map = {
        'id': 'notif-3',
        'userId': 'user-3',
        'type': 'unknown_type',
        'category': 'unknown_category',
        'title': 'Test',
        'message': 'Test',
        'priority': 'unknown_priority',
        'createdAt': createdAt,
      };

      final notification = Notification.fromMap(map);

      expect(notification.type, NotificationType.system);
      expect(notification.category, NotificationCategory.system);
      expect(notification.priority, NotificationPriority.normal);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = <String, dynamic>{};

      final notification = Notification.fromMap(map);

      expect(notification.id, '');
      expect(notification.userId, '');
      expect(notification.type, NotificationType.system);
      expect(notification.category, NotificationCategory.system);
      expect(notification.title, '');
      expect(notification.message, '');
      expect(notification.isRead, false);
      expect(notification.priority, NotificationPriority.normal);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Notification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.system,
        category: NotificationCategory.system,
        title: 'Original Title',
        message: 'Original Message',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isRead: true,
        priority: NotificationPriority.high,
      );

      expect(updated.id, 'notif-1');
      expect(updated.userId, 'user-1');
      expect(updated.title, 'Updated Title');
      expect(updated.message, 'Original Message');
      expect(updated.isRead, true);
      expect(updated.priority, NotificationPriority.high);
      expect(original.title, 'Original Title');
      expect(original.isRead, false);
    });

    test('copyWith preserves original values when not specified', () {
      final original = Notification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.orderStatus,
        category: NotificationCategory.orders,
        title: 'Title',
        message: 'Message',
        actionUrl: '/url',
        isRead: true,
        priority: NotificationPriority.high,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith();

      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.type, original.type);
      expect(updated.category, original.category);
      expect(updated.title, original.title);
      expect(updated.message, original.message);
      expect(updated.actionUrl, original.actionUrl);
      expect(updated.isRead, original.isRead);
      expect(updated.priority, original.priority);
    });

    test('toString returns formatted string', () {
      final notification = Notification(
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.orderStatus,
        category: NotificationCategory.orders,
        title: 'Order Update',
        message: 'Your order is on the way',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final str = notification.toString();

      expect(str, contains('notif-1'));
      expect(str, contains('Order Update'));
      expect(str, contains('Order Status'));
      expect(str, contains('isRead: false'));
    });
  });
}
