import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_type.dart';
import 'notification_category.dart';
import 'notification_priority.dart';

enum ScheduleStatus {
  pending,
  sent,
  failed,
  cancelled,
}

extension ScheduleStatusExtension on ScheduleStatus {
  String get displayName {
    switch (this) {
      case ScheduleStatus.pending:
        return 'Pending';
      case ScheduleStatus.sent:
        return 'Sent';
      case ScheduleStatus.failed:
        return 'Failed';
      case ScheduleStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get name => toString().split('.').last;

  Color get color {
    switch (this) {
      case ScheduleStatus.pending:
        return Color(0xFF9E9E9E);
      case ScheduleStatus.sent:
        return Color(0xFF4CAF50);
      case ScheduleStatus.failed:
        return Color(0xFFF44336);
      case ScheduleStatus.cancelled:
        return Color(0xFFFF9800);
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleStatus.pending:
        return Icons.schedule;
      case ScheduleStatus.sent:
        return Icons.check_circle;
      case ScheduleStatus.failed:
        return Icons.error;
      case ScheduleStatus.cancelled:
        return Icons.cancel;
    }
  }
}

enum ScheduleFrequency {
  once,
  daily,
  weekly,
  monthly,
  custom,
}

extension ScheduleFrequencyExtension on ScheduleFrequency {
  String get displayName {
    switch (this) {
      case ScheduleFrequency.once:
        return 'Once';
      case ScheduleFrequency.daily:
        return 'Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.monthly:
        return 'Monthly';
      case ScheduleFrequency.custom:
        return 'Custom';
    }
  }

  String get name => toString().split('.').last;
}

class ScheduledNotification {
  final String id;
  final String name;
  final String description;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String message;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final NotificationPriority priority;
  final ScheduleStatus status;
  final ScheduleFrequency frequency;
  final DateTime scheduledFor;
  final DateTime? recurringUntil;
  final int? recurringInterval; // in days
  final String? timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? sentAt;
  final String? errorMessage;
  final int retryCount;
  final int maxRetries;

  ScheduledNotification({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.actionUrl,
    this.metadata,
    this.priority = NotificationPriority.normal,
    this.status = ScheduleStatus.pending,
    this.frequency = ScheduleFrequency.once,
    required this.scheduledFor,
    this.recurringUntil,
    this.recurringInterval,
    this.timezone,
    required this.createdAt,
    this.updatedAt,
    this.sentAt,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'category': category.name,
    'title': title,
    'message': message,
    'actionUrl': actionUrl,
    'metadata': metadata,
    'priority': priority.name,
    'status': status.name,
    'frequency': frequency.name,
    'scheduledFor': Timestamp.fromDate(scheduledFor),
    'recurringUntil': recurringUntil != null
        ? Timestamp.fromDate(recurringUntil!)
        : null,
    'recurringInterval': recurringInterval,
    'timezone': timezone,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    'errorMessage': errorMessage,
    'retryCount': retryCount,
    'maxRetries': maxRetries,
  };

  factory ScheduledNotification.fromMap(Map<String, dynamic> m) {
    return ScheduledNotification(
      id: m['id'] ?? '',
      name: m['name'] ?? '',
      description: m['description'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => NotificationType.system,
      ),
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == m['category'],
        orElse: () => NotificationCategory.system,
      ),
      title: m['title'] ?? '',
      message: m['message'] ?? '',
      actionUrl: m['actionUrl'],
      metadata: m['metadata'] as Map<String, dynamic>?,
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == m['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      status: ScheduleStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => ScheduleStatus.pending,
      ),
      frequency: ScheduleFrequency.values.firstWhere(
        (f) => f.name == m['frequency'],
        orElse: () => ScheduleFrequency.once,
      ),
      scheduledFor: (m['scheduledFor'] as Timestamp).toDate(),
      recurringUntil: m['recurringUntil'] != null
          ? (m['recurringUntil'] as Timestamp).toDate()
          : null,
      recurringInterval: m['recurringInterval'],
      timezone: m['timezone'],
      createdAt: (m['createdAt'] as Timestamp).toDate(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
      sentAt: m['sentAt'] != null ? (m['sentAt'] as Timestamp).toDate() : null,
      errorMessage: m['errorMessage'],
      retryCount: m['retryCount'] ?? 0,
      maxRetries: m['maxRetries'] ?? 3,
    );
  }

  ScheduledNotification copyWith({
    String? id,
    String? name,
    String? description,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? message,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    NotificationPriority? priority,
    ScheduleStatus? status,
    ScheduleFrequency? frequency,
    DateTime? scheduledFor,
    DateTime? recurringUntil,
    int? recurringInterval,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? sentAt,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
  }) {
    return ScheduledNotification(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      recurringUntil: recurringUntil ?? this.recurringUntil,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sentAt: sentAt ?? this.sentAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  bool get isOverdue {
    return status == ScheduleStatus.pending && DateTime.now().isAfter(scheduledFor);
  }

  bool get isRecurring {
    return frequency != ScheduleFrequency.once;
  }

  bool get canRetry {
    return status == ScheduleStatus.failed && retryCount < maxRetries;
  }

  @override
  String toString() {
    return 'ScheduledNotification(id: $id, name: $name, status: ${status.displayName}, scheduledFor: $scheduledFor)';
  }
}