import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification batches
class NotificationBatch {
  final String id;
  final String name;
  final String description;
  final String templateId;
  final List<String> recipientIds;
  final int totalRecipients;
  final int sentCount;
  final int deliveredCount;
  final int failedCount;
  final BatchStatus status;
  final DateTime scheduledFor;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationBatch({
    required this.id,
    required this.name,
    required this.description,
    required this.templateId,
    required this.recipientIds,
    required this.totalRecipients,
    required this.sentCount,
    required this.deliveredCount,
    required this.failedCount,
    required this.status,
    required this.scheduledFor,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    required this.metadata,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationBatch.fromJson(Map<String, dynamic> json) {
    return NotificationBatch(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      templateId: json['templateId'] as String,
      recipientIds: (json['recipientIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalRecipients: json['totalRecipients'] as int,
      sentCount: json['sentCount'] as int,
      deliveredCount: json['deliveredCount'] as int,
      failedCount: json['failedCount'] as int,
      status: BatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BatchStatus.pending,
      ),
      scheduledFor: (json['scheduledFor'] as Timestamp).toDate(),
      startedAt: json['startedAt'] != null
          ? (json['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'templateId': templateId,
      'recipientIds': recipientIds,
      'totalRecipients': totalRecipients,
      'sentCount': sentCount,
      'deliveredCount': deliveredCount,
      'failedCount': failedCount,
      'status': status.name,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'errorMessage': errorMessage,
      'metadata': metadata,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NotificationBatch copyWith({
    String? id,
    String? name,
    String? description,
    String? templateId,
    List<String>? recipientIds,
    int? totalRecipients,
    int? sentCount,
    int? deliveredCount,
    int? failedCount,
    BatchStatus? status,
    DateTime? scheduledFor,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationBatch(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      templateId: templateId ?? this.templateId,
      recipientIds: recipientIds ?? this.recipientIds,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      failedCount: failedCount ?? this.failedCount,
      status: status ?? this.status,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progress => totalRecipients > 0
      ? (sentCount / totalRecipients) * 100
      : 0;

  double get deliveryRate => sentCount > 0
      ? (deliveredCount / sentCount) * 100
      : 0;

  double get failureRate => sentCount > 0
      ? (failedCount / sentCount) * 100
      : 0;

  int get remainingCount => totalRecipients - sentCount;

  bool get isPending => status == BatchStatus.pending;
  bool get isProcessing => status == BatchStatus.processing;
  bool get isCompleted => status == BatchStatus.completed;
  bool get isFailed => status == BatchStatus.failed;
  bool get isCancelled => status == BatchStatus.cancelled;
}

enum BatchStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Model for batch retry configuration
class BatchRetryConfig {
  final int maxRetries;
  final int retryDelaySeconds;
  final bool exponentialBackoff;
  final double backoffMultiplier;

  BatchRetryConfig({
    this.maxRetries = 3,
    this.retryDelaySeconds = 60,
    this.exponentialBackoff = true,
    this.backoffMultiplier = 2.0,
  });

  factory BatchRetryConfig.fromJson(Map<String, dynamic> json) {
    return BatchRetryConfig(
      maxRetries: json['maxRetries'] as int? ?? 3,
      retryDelaySeconds: json['retryDelaySeconds'] as int? ?? 60,
      exponentialBackoff: json['exponentialBackoff'] as bool? ?? true,
      backoffMultiplier: (json['backoffMultiplier'] as num?)?.toDouble() ?? 2.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxRetries': maxRetries,
      'retryDelaySeconds': retryDelaySeconds,
      'exponentialBackoff': exponentialBackoff,
      'backoffMultiplier': backoffMultiplier,
    };
  }

  int getRetryDelay(int attempt) {
    if (!exponentialBackoff) {
      return retryDelaySeconds;
    }
    return (retryDelaySeconds * pow(backoffMultiplier, attempt)).toInt();
  }

  double pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

/// Model for batch item (individual notification in a batch)
class BatchItem {
  final String id;
  final String batchId;
  final String recipientId;
  final String recipientEmail;
  final String? recipientPhone;
  final Map<String, dynamic> variables;
  final BatchItemStatus status;
  final int retryCount;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  BatchItem({
    required this.id,
    required this.batchId,
    required this.recipientId,
    required this.recipientEmail,
    this.recipientPhone,
    required this.variables,
    required this.status,
    required this.retryCount,
    this.sentAt,
    this.deliveredAt,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BatchItem.fromJson(Map<String, dynamic> json) {
    return BatchItem(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      recipientId: json['recipientId'] as String,
      recipientEmail: json['recipientEmail'] as String,
      recipientPhone: json['recipientPhone'] as String?,
      variables: json['variables'] as Map<String, dynamic>? ?? {},
      status: BatchItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BatchItemStatus.pending,
      ),
      retryCount: json['retryCount'] as int? ?? 0,
      sentAt: json['sentAt'] != null
          ? (json['sentAt'] as Timestamp).toDate()
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? (json['deliveredAt'] as Timestamp).toDate()
          : null,
      errorMessage: json['errorMessage'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'recipientPhone': recipientPhone,
      'variables': variables,
      'status': status.name,
      'retryCount': retryCount,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'deliveredAt': deliveredAt != null
          ? Timestamp.fromDate(deliveredAt!)
          : null,
      'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BatchItem copyWith({
    String? id,
    String? batchId,
    String? recipientId,
    String? recipientEmail,
    String? recipientPhone,
    Map<String, dynamic>? variables,
    BatchItemStatus? status,
    int? retryCount,
    DateTime? sentAt,
    DateTime? deliveredAt,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BatchItem(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      recipientId: recipientId ?? this.recipientId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      variables: variables ?? this.variables,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == BatchItemStatus.pending;
  bool get isSent => status == BatchItemStatus.sent;
  bool get isDelivered => status == BatchItemStatus.delivered;
  bool get isFailed => status == BatchItemStatus.failed;
  bool get isRetrying => status == BatchItemStatus.retrying;
}

enum BatchItemStatus {
  pending,
  sent,
  delivered,
  failed,
  retrying,
}