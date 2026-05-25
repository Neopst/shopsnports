import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_type.dart';
import 'notification_category.dart';
import 'notification_priority.dart';

enum DeliveryStatus {
  pending,
  sent,
  delivered,
  failed,
  opened,
  clicked,
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.sent:
        return 'Sent';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
      case DeliveryStatus.opened:
        return 'Opened';
      case DeliveryStatus.clicked:
        return 'Clicked';
    }
  }

  String get name => toString().split('.').last;

  Color get color {
    switch (this) {
      case DeliveryStatus.pending:
        return Color(0xFF9E9E9E);
      case DeliveryStatus.sent:
        return Color(0xFF2196F3);
      case DeliveryStatus.delivered:
        return Color(0xFF4CAF50);
      case DeliveryStatus.failed:
        return Color(0xFFF44336);
      case DeliveryStatus.opened:
        return Color(0xFF9C27B0);
      case DeliveryStatus.clicked:
        return Color(0xFFFF9800);
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryStatus.pending:
        return Icons.schedule;
      case DeliveryStatus.sent:
        return Icons.send;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      case DeliveryStatus.failed:
        return Icons.error;
      case DeliveryStatus.opened:
        return Icons.visibility;
      case DeliveryStatus.clicked:
        return Icons.touch_app;
    }
  }
}

class NotificationHistory {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String message;
  final String? actionUrl;
  final DeliveryStatus deliveryStatus;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DateTime? clickedAt;
  final String? deliveryError;
  final Map<String, dynamic>? metadata;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.actionUrl,
    this.deliveryStatus = DeliveryStatus.pending,
    this.sentAt,
    this.deliveredAt,
    this.openedAt,
    this.clickedAt,
    this.deliveryError,
    this.metadata,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'category': category.name,
    'title': title,
    'message': message,
    'actionUrl': actionUrl,
    'deliveryStatus': deliveryStatus.name,
    'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
    'clickedAt': clickedAt != null ? Timestamp.fromDate(clickedAt!) : null,
    'deliveryError': deliveryError,
    'metadata': metadata,
    'priority': priority.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  factory NotificationHistory.fromMap(Map<String, dynamic> m) {
    return NotificationHistory(
      id: m['id'] ?? '',
      userId: m['userId'] ?? '',
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
      deliveryStatus: DeliveryStatus.values.firstWhere(
        (s) => s.name == m['deliveryStatus'],
        orElse: () => DeliveryStatus.pending,
      ),
      sentAt: m['sentAt'] != null ? (m['sentAt'] as Timestamp).toDate() : null,
      deliveredAt: m['deliveredAt'] != null
          ? (m['deliveredAt'] as Timestamp).toDate()
          : null,
      openedAt: m['openedAt'] != null ? (m['openedAt'] as Timestamp).toDate() : null,
      clickedAt: m['clickedAt'] != null ? (m['clickedAt'] as Timestamp).toDate() : null,
      deliveryError: m['deliveryError'],
      metadata: m['metadata'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == m['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdAt: m['createdAt'] != null
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  NotificationHistory copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? message,
    String? actionUrl,
    DeliveryStatus? deliveryStatus,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? openedAt,
    DateTime? clickedAt,
    String? deliveryError,
    Map<String, dynamic>? metadata,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      openedAt: openedAt ?? this.openedAt,
      clickedAt: clickedAt ?? this.clickedAt,
      deliveryError: deliveryError ?? this.deliveryError,
      metadata: metadata ?? this.metadata,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDelivered =>
      deliveryStatus == DeliveryStatus.delivered ||
      deliveryStatus == DeliveryStatus.opened ||
      deliveryStatus == DeliveryStatus.clicked;

  bool get isFailed => deliveryStatus == DeliveryStatus.failed;

  bool get isOpened => deliveryStatus == DeliveryStatus.opened || deliveryStatus == DeliveryStatus.clicked;

  bool get isClicked => deliveryStatus == DeliveryStatus.clicked;

  @override
  String toString() {
    return 'NotificationHistory(id: $id, title: $title, type: ${type.displayName}, deliveryStatus: ${deliveryStatus.displayName})';
  }
}