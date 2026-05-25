import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_priority.dart';

void main() {
  group('NotificationPriority', () {
    test('has correct display names', () {
      expect(NotificationPriority.low.displayName, 'Low');
      expect(NotificationPriority.normal.displayName, 'Normal');
      expect(NotificationPriority.high.displayName, 'High');
      expect(NotificationPriority.critical.displayName, 'Critical');
    });

    test('has correct colors', () {
      expect(NotificationPriority.low.color, Colors.grey);
      expect(NotificationPriority.normal.color, Colors.blue);
      expect(NotificationPriority.high.color, Colors.orange);
      expect(NotificationPriority.critical.color, Colors.red);
    });

    test('has all expected values', () {
      expect(NotificationPriority.values.length, 4);
      expect(
        NotificationPriority.values,
        containsAll([
          NotificationPriority.low,
          NotificationPriority.normal,
          NotificationPriority.high,
          NotificationPriority.critical,
        ]),
      );
    });

    test('displayName returns correct value for each priority', () {
      for (final priority in NotificationPriority.values) {
        expect(priority.displayName, isNotEmpty);
      }
    });

    test('color returns valid Color for each priority', () {
      for (final priority in NotificationPriority.values) {
        expect(priority.color, isA<Color>());
      }
    });

    test('priority ordering: low < normal < high < critical', () {
      final priorities = NotificationPriority.values;
      expect(priorities.indexOf(NotificationPriority.low), lessThan(priorities.indexOf(NotificationPriority.normal)));
      expect(priorities.indexOf(NotificationPriority.normal), lessThan(priorities.indexOf(NotificationPriority.high)));
      expect(priorities.indexOf(NotificationPriority.high), lessThan(priorities.indexOf(NotificationPriority.critical)));
    });
  });
}
