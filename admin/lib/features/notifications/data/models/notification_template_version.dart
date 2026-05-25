import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification template versions
class NotificationTemplateVersion {
  final String id;
  final String templateId;
  final int versionNumber;
  final String name;
  final String subject;
  final String body;
  final Map<String, dynamic> variables;
  final TemplateVersionStatus status;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? publishedBy;

  NotificationTemplateVersion({
    required this.id,
    required this.templateId,
    required this.versionNumber,
    required this.name,
    required this.subject,
    required this.body,
    required this.variables,
    required this.status,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.publishedAt,
    this.publishedBy,
  });

  factory NotificationTemplateVersion.fromJson(Map<String, dynamic> json) {
    return NotificationTemplateVersion(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      versionNumber: json['versionNumber'] as int,
      name: json['name'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      variables: json['variables'] as Map<String, dynamic>,
      status: TemplateVersionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TemplateVersionStatus.draft,
      ),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      publishedAt: json['publishedAt'] != null
          ? (json['publishedAt'] as Timestamp).toDate()
          : null,
      publishedBy: json['publishedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'versionNumber': versionNumber,
      'name': name,
      'subject': subject,
      'body': body,
      'variables': variables,
      'status': status.name,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'publishedAt': publishedAt != null
          ? Timestamp.fromDate(publishedAt!)
          : null,
      'publishedBy': publishedBy,
    };
  }

  NotificationTemplateVersion copyWith({
    String? id,
    String? templateId,
    int? versionNumber,
    String? name,
    String? subject,
    String? body,
    Map<String, dynamic>? variables,
    TemplateVersionStatus? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? publishedAt,
    String? publishedBy,
  }) {
    return NotificationTemplateVersion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      versionNumber: versionNumber ?? this.versionNumber,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      variables: variables ?? this.variables,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
    );
  }

  bool get isPublished => status == TemplateVersionStatus.published;
  bool get isDraft => status == TemplateVersionStatus.draft;
  bool get isArchived => status == TemplateVersionStatus.archived;
}

enum TemplateVersionStatus {
  draft,
  published,
  archived,
}

/// Model for A/B test campaigns
class NotificationABTest {
  final String id;
  final String name;
  final String description;
  final String templateId;
  final List<ABTestVariant> variants;
  final ABTestStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final int totalRecipients;
  final int sentCount;
  final Map<String, ABTestMetrics> metrics;
  final String? winningVariantId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationABTest({
    required this.id,
    required this.name,
    required this.description,
    required this.templateId,
    required this.variants,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.totalRecipients,
    required this.sentCount,
    required this.metrics,
    this.winningVariantId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationABTest.fromJson(Map<String, dynamic> json) {
    return NotificationABTest(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      templateId: json['templateId'] as String,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ABTestVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: ABTestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ABTestStatus.draft,
      ),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      totalRecipients: json['totalRecipients'] as int,
      sentCount: json['sentCount'] as int,
      metrics: (json['metrics'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(
                    key,
                    ABTestMetrics.fromJson(value as Map<String, dynamic>),
                  )) ??
          {},
      winningVariantId: json['winningVariantId'] as String?,
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
      'variants': variants.map((e) => e.toJson()).toList(),
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'totalRecipients': totalRecipients,
      'sentCount': sentCount,
      'metrics': metrics.map((key, value) => MapEntry(key, value.toJson())),
      'winningVariantId': winningVariantId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NotificationABTest copyWith({
    String? id,
    String? name,
    String? description,
    String? templateId,
    List<ABTestVariant>? variants,
    ABTestStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? totalRecipients,
    int? sentCount,
    Map<String, ABTestMetrics>? metrics,
    String? winningVariantId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationABTest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      templateId: templateId ?? this.templateId,
      variants: variants ?? this.variants,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      sentCount: sentCount ?? this.sentCount,
      metrics: metrics ?? this.metrics,
      winningVariantId: winningVariantId ?? this.winningVariantId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get completionRate =>
      totalRecipients > 0 ? (sentCount / totalRecipients) * 100 : 0;

  bool get isComplete => status == ABTestStatus.completed;
  bool get isActive => status == ABTestStatus.active;
  bool get isDraft => status == ABTestStatus.draft;
}

enum ABTestStatus {
  draft,
  active,
  paused,
  completed,
  cancelled,
}

class ABTestVariant {
  final String id;
  final String name;
  final String versionId;
  final double allocation; // Percentage of recipients (0-100)
  final ABTestMetrics metrics;

  ABTestVariant({
    required this.id,
    required this.name,
    required this.versionId,
    required this.allocation,
    required this.metrics,
  });

  factory ABTestVariant.fromJson(Map<String, dynamic> json) {
    return ABTestVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      versionId: json['versionId'] as String,
      allocation: (json['allocation'] as num).toDouble(),
      metrics: ABTestMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'versionId': versionId,
      'allocation': allocation,
      'metrics': metrics.toJson(),
    };
  }
}

class ABTestMetrics {
  final int sent;
  final int delivered;
  final int opened;
  final int clicked;
  final int converted;
  final DateTime? lastUpdated;

  ABTestMetrics({
    required this.sent,
    required this.delivered,
    required this.opened,
    required this.clicked,
    required this.converted,
    this.lastUpdated,
  });

  factory ABTestMetrics.fromJson(Map<String, dynamic> json) {
    return ABTestMetrics(
      sent: json['sent'] as int,
      delivered: json['delivered'] as int,
      opened: json['opened'] as int,
      clicked: json['clicked'] as int,
      converted: json['converted'] as int,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sent': sent,
      'delivered': delivered,
      'opened': opened,
      'clicked': clicked,
      'converted': converted,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
    };
  }

  double get deliveryRate => sent > 0 ? (delivered / sent) * 100 : 0;
  double get openRate => delivered > 0 ? (opened / delivered) * 100 : 0;
  double get clickRate => opened > 0 ? (clicked / opened) * 100 : 0;
  double get conversionRate => clicked > 0 ? (converted / clicked) * 100 : 0;
}