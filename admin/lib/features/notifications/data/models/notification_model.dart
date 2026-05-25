import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_type.dart';
import 'notification_category.dart';
import 'notification_priority.dart';

enum NotificationStatus {
  pending,
  sent,
  delivered,
  failed,
  permanently_failed,
  cancelled,
}

extension NotificationStatusExtension on NotificationStatus {
  String get displayName {
    switch (this) {
      case NotificationStatus.pending:
        return 'Pending';
      case NotificationStatus.sent:
        return 'Sent';
      case NotificationStatus.delivered:
        return 'Delivered';
      case NotificationStatus.failed:
        return 'Failed';
      case NotificationStatus.permanently_failed:
        return 'Permanently Failed';
      case NotificationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get name => toString().split('.').last;
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String message;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final NotificationPriority priority;
  final NotificationStatus status;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? sentAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.actionUrl,
    this.isRead = false,
    this.readAt,
    this.metadata,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.pending,
    this.retryCount = 0,
    this.lastRetryAt,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
    this.sentAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'category': category.name,
    'title': title,
    'message': message,
    'actionUrl': actionUrl,
    'isRead': isRead,
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    'metadata': metadata,
    'priority': priority.name,
    'status': status.name,
    'retryCount': retryCount,
    'lastRetryAt': lastRetryAt != null ? Timestamp.fromDate(lastRetryAt!) : null,
    'errorMessage': errorMessage,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  factory Notification.fromMap(Map<String, dynamic> m) {
    return Notification(
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
      isRead: m['isRead'] ?? false,
      readAt: m['readAt'] != null ? (m['readAt'] as Timestamp).toDate() : null,
      metadata: m['metadata'],
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == m['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => NotificationStatus.pending,
      ),
      retryCount: m['retryCount'] ?? 0,
      lastRetryAt: m['lastRetryAt'] != null
          ? (m['lastRetryAt'] as Timestamp).toDate()
          : null,
      errorMessage: m['errorMessage'],
      createdAt: m['createdAt'] != null
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Notification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? message,
    String? actionUrl,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    NotificationPriority? priority,
    NotificationStatus? status,
    int? retryCount,
    DateTime? lastRetryAt,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: ${type.displayName}, status: ${status.displayName}, isRead: $isRead)';
  }

  bool get canRetry {
    return (status == NotificationStatus.failed ||
            status == NotificationStatus.permanently_failed) &&
        retryCount < 3;
  }

  bool get isFailed {
    return status == NotificationStatus.failed ||
        status == NotificationStatus.permanently_failed;
  }
}
