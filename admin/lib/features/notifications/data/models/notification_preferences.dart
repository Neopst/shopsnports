import 'package:flutter/material.dart';

class NotificationPreferences {
  bool salesEnabled;
  bool ordersEnabled;
  bool reviewsEnabled;
  bool usersEnabled;
  bool inventoryEnabled;
  bool systemEnabled;
  bool emailNotifications;
  bool pushNotifications;
  bool soundAlert;
  TimeOfDay? quietHoursStart;
  TimeOfDay? quietHoursEnd;

  NotificationPreferences({
    this.salesEnabled = true,
    this.ordersEnabled = true,
    this.reviewsEnabled = true,
    this.usersEnabled = true,
    this.inventoryEnabled = true,
    this.systemEnabled = true,
    this.emailNotifications = false,
    this.pushNotifications = true,
    this.soundAlert = true,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  Map<String, dynamic> toMap() => {
    'salesEnabled': salesEnabled,
    'ordersEnabled': ordersEnabled,
    'reviewsEnabled': reviewsEnabled,
    'usersEnabled': usersEnabled,
    'inventoryEnabled': inventoryEnabled,
    'systemEnabled': systemEnabled,
    'emailNotifications': emailNotifications,
    'pushNotifications': pushNotifications,
    'soundAlert': soundAlert,
    'quietHoursStart': quietHoursStart != null
        ? '${quietHoursStart!.hour}:${quietHoursStart!.minute}'
        : null,
    'quietHoursEnd': quietHoursEnd != null
        ? '${quietHoursEnd!.hour}:${quietHoursEnd!.minute}'
        : null,
  };

  factory NotificationPreferences.fromMap(Map<String, dynamic> m) {
    TimeOfDay? parseTimeOfDay(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return NotificationPreferences(
      salesEnabled: m['salesEnabled'] ?? true,
      ordersEnabled: m['ordersEnabled'] ?? true,
      reviewsEnabled: m['reviewsEnabled'] ?? true,
      usersEnabled: m['usersEnabled'] ?? true,
      inventoryEnabled: m['inventoryEnabled'] ?? true,
      systemEnabled: m['systemEnabled'] ?? true,
      emailNotifications: m['emailNotifications'] ?? false,
      pushNotifications: m['pushNotifications'] ?? true,
      soundAlert: m['soundAlert'] ?? true,
      quietHoursStart: parseTimeOfDay(m['quietHoursStart']),
      quietHoursEnd: parseTimeOfDay(m['quietHoursEnd']),
    );
  }

  NotificationPreferences copyWith({
    bool? salesEnabled,
    bool? ordersEnabled,
    bool? reviewsEnabled,
    bool? usersEnabled,
    bool? inventoryEnabled,
    bool? systemEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? soundAlert,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
  }) {
    return NotificationPreferences(
      salesEnabled: salesEnabled ?? this.salesEnabled,
      ordersEnabled: ordersEnabled ?? this.ordersEnabled,
      reviewsEnabled: reviewsEnabled ?? this.reviewsEnabled,
      usersEnabled: usersEnabled ?? this.usersEnabled,
      inventoryEnabled: inventoryEnabled ?? this.inventoryEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      soundAlert: soundAlert ?? this.soundAlert,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
