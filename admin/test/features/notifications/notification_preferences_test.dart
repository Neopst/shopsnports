import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('creates preferences with default values', () {
      final prefs = NotificationPreferences();

      expect(prefs.salesEnabled, true);
      expect(prefs.ordersEnabled, true);
      expect(prefs.reviewsEnabled, true);
      expect(prefs.usersEnabled, true);
      expect(prefs.inventoryEnabled, true);
      expect(prefs.systemEnabled, true);
      expect(prefs.emailNotifications, false);
      expect(prefs.pushNotifications, true);
      expect(prefs.soundAlert, true);
      expect(prefs.quietHoursStart, null);
      expect(prefs.quietHoursEnd, null);
    });

    test('creates preferences with custom values', () {
      final prefs = NotificationPreferences(
        salesEnabled: false,
        ordersEnabled: false,
        reviewsEnabled: false,
        usersEnabled: false,
        inventoryEnabled: false,
        systemEnabled: false,
        emailNotifications: true,
        pushNotifications: false,
        soundAlert: false,
        quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
        quietHoursEnd: const TimeOfDay(hour: 8, minute: 0),
      );

      expect(prefs.salesEnabled, false);
      expect(prefs.ordersEnabled, false);
      expect(prefs.reviewsEnabled, false);
      expect(prefs.usersEnabled, false);
      expect(prefs.inventoryEnabled, false);
      expect(prefs.systemEnabled, false);
      expect(prefs.emailNotifications, true);
      expect(prefs.pushNotifications, false);
      expect(prefs.soundAlert, false);
      expect(prefs.quietHoursStart, const TimeOfDay(hour: 22, minute: 0));
      expect(prefs.quietHoursEnd, const TimeOfDay(hour: 8, minute: 0));
    });

    test('toMap serializes correctly', () {
      final prefs = NotificationPreferences(
        salesEnabled: false,
        ordersEnabled: true,
        emailNotifications: true,
        pushNotifications: false,
        quietHoursStart: const TimeOfDay(hour: 10, minute: 30),
        quietHoursEnd: const TimeOfDay(hour: 18, minute: 0),
      );

      final map = prefs.toMap();

      expect(map['salesEnabled'], false);
      expect(map['ordersEnabled'], true);
      expect(map['reviewsEnabled'], true);
      expect(map['usersEnabled'], true);
      expect(map['inventoryEnabled'], true);
      expect(map['systemEnabled'], true);
      expect(map['emailNotifications'], true);
      expect(map['pushNotifications'], false);
      expect(map['soundAlert'], true);
      expect(map['quietHoursStart'], '10:30');
      expect(map['quietHoursEnd'], '18:0');
    });

    test('toMap handles null quiet hours', () {
      final prefs = NotificationPreferences(
        quietHoursStart: null,
        quietHoursEnd: null,
      );

      final map = prefs.toMap();

      expect(map['quietHoursStart'], null);
      expect(map['quietHoursEnd'], null);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'salesEnabled': false,
        'ordersEnabled': false,
        'reviewsEnabled': false,
        'usersEnabled': false,
        'inventoryEnabled': false,
        'systemEnabled': false,
        'emailNotifications': true,
        'pushNotifications': false,
        'soundAlert': false,
        'quietHoursStart': '22:0',
        'quietHoursEnd': '8:30',
      };

      final prefs = NotificationPreferences.fromMap(map);

      expect(prefs.salesEnabled, false);
      expect(prefs.ordersEnabled, false);
      expect(prefs.reviewsEnabled, false);
      expect(prefs.usersEnabled, false);
      expect(prefs.inventoryEnabled, false);
      expect(prefs.systemEnabled, false);
      expect(prefs.emailNotifications, true);
      expect(prefs.pushNotifications, false);
      expect(prefs.soundAlert, false);
      expect(prefs.quietHoursStart, const TimeOfDay(hour: 22, minute: 0));
      expect(prefs.quietHoursEnd, const TimeOfDay(hour: 8, minute: 30));
    });

    test('fromMap handles null quiet hours', () {
      final map = {
        'quietHoursStart': null,
        'quietHoursEnd': null,
      };

      final prefs = NotificationPreferences.fromMap(map);

      expect(prefs.quietHoursStart, null);
      expect(prefs.quietHoursEnd, null);
    });

    test('fromMap uses default values for missing fields', () {
      final map = <String, dynamic>{};

      final prefs = NotificationPreferences.fromMap(map);

      expect(prefs.salesEnabled, true);
      expect(prefs.ordersEnabled, true);
      expect(prefs.reviewsEnabled, true);
      expect(prefs.usersEnabled, true);
      expect(prefs.inventoryEnabled, true);
      expect(prefs.systemEnabled, true);
      expect(prefs.emailNotifications, false);
      expect(prefs.pushNotifications, true);
      expect(prefs.soundAlert, true);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = NotificationPreferences(
        salesEnabled: true,
        ordersEnabled: true,
        emailNotifications: false,
      );

      final updated = original.copyWith(
        salesEnabled: false,
        emailNotifications: true,
        quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
      );

      expect(updated.salesEnabled, false);
      expect(updated.ordersEnabled, true);
      expect(updated.emailNotifications, true);
      expect(updated.quietHoursStart, const TimeOfDay(hour: 22, minute: 0));
      expect(original.salesEnabled, true);
      expect(original.emailNotifications, false);
    });

    test('copyWith preserves original values when not specified', () {
      final original = NotificationPreferences(
        salesEnabled: false,
        ordersEnabled: false,
        reviewsEnabled: false,
        usersEnabled: false,
        inventoryEnabled: false,
        systemEnabled: false,
        emailNotifications: true,
        pushNotifications: false,
        soundAlert: false,
        quietHoursStart: const TimeOfDay(hour: 22, minute: 0),
        quietHoursEnd: const TimeOfDay(hour: 8, minute: 0),
      );

      final updated = original.copyWith();

      expect(updated.salesEnabled, original.salesEnabled);
      expect(updated.ordersEnabled, original.ordersEnabled);
      expect(updated.reviewsEnabled, original.reviewsEnabled);
      expect(updated.usersEnabled, original.usersEnabled);
      expect(updated.inventoryEnabled, original.inventoryEnabled);
      expect(updated.systemEnabled, original.systemEnabled);
      expect(updated.emailNotifications, original.emailNotifications);
      expect(updated.pushNotifications, original.pushNotifications);
      expect(updated.soundAlert, original.soundAlert);
      expect(updated.quietHoursStart, original.quietHoursStart);
      expect(updated.quietHoursEnd, original.quietHoursEnd);
    });

    test('quiet hours roundtrip through toMap and fromMap', () {
      final original = NotificationPreferences(
        quietHoursStart: const TimeOfDay(hour: 23, minute: 59),
        quietHoursEnd: const TimeOfDay(hour: 6, minute: 30),
      );

      final map = original.toMap();
      final restored = NotificationPreferences.fromMap(map);

      expect(restored.quietHoursStart, original.quietHoursStart);
      expect(restored.quietHoursEnd, original.quietHoursEnd);
    });
  });
}
