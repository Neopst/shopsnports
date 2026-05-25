import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification A/B testing campaigns
class NotificationABTest {
  final String id;
  final String name;
  final String description;
  final String templateId;
  final List<ABTestVariant> variants;
  final ABTestStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final ABTestResults? results;
  final int totalRecipients;
  final int totalSent;
  final String createdBy;
  final String? endedBy;
  final ABTestWinner? winner;
  final Map<String, dynamic> metadata;

  NotificationABTest({
    required this.id,
    required this.name,
    required this.description,
    required this.templateId,
    required this.variants,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.results,
    required this.totalRecipients,
    required this.totalSent,
    required this.createdBy,
    this.endedBy,
    this.winner,
    this.metadata = const {},
  });

  factory NotificationABTest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationABTest(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      templateId: data['templateId'] as String,
      variants: (data['variants'] as List)
          .map((v) => ABTestVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      status: ABTestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ABTestStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as Timestamp).toDate()
          : null,
      results: data['results'] != null
          ? ABTestResults.fromJson(data['results'] as Map<String, dynamic>)
          : null,
      totalRecipients: data['totalRecipients'] as int,
      totalSent: data['totalSent'] as int,
      createdBy: data['createdBy'] as String,
      endedBy: data['endedBy'] as String?,
      winner: data['winner'] != null
          ? ABTestWinner.fromJson(data['winner'] as Map<String, dynamic>)
          : null,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'templateId': templateId,
      'variants': variants.map((v) => v.toJson()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'results': results?.toJson(),
      'totalRecipients': totalRecipients,
      'totalSent': totalSent,
      'createdBy': createdBy,
      'endedBy': endedBy,
      'winner': winner?.toJson(),
      'metadata': metadata,
    };
  }

  NotificationABTest copyWith({
    String? id,
    String? name,
    String? description,
    String? templateId,
    List<ABTestVariant>? variants,
    ABTestStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    ABTestResults? results,
    int? totalRecipients,
    int? totalSent,
    String? createdBy,
    String? endedBy,
    ABTestWinner? winner,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationABTest(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      templateId: templateId ?? this.templateId,
      variants: variants ?? this.variants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      results: results ?? this.results,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      totalSent: totalSent ?? this.totalSent,
      createdBy: createdBy ?? this.createdBy,
      endedBy: endedBy ?? this.endedBy,
      winner: winner ?? this.winner,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// A/B test variant
class ABTestVariant {
  final String id;
  final String name;
  final String subject;
  final String body;
  final int recipientCount;
  final int sentCount;
  final int deliveredCount;
  final int openedCount;
  final int clickedCount;
  final double openRate;
  final double clickRate;
  final double conversionRate;
  final bool isControl;

  ABTestVariant({
    required this.id,
    required this.name,
    required this.subject,
    required this.body,
    required this.recipientCount,
    required this.sentCount,
    required this.deliveredCount,
    required this.openedCount,
    required this.clickedCount,
    required this.openRate,
    required this.clickRate,
    required this.conversionRate,
    this.isControl = false,
  });

  factory ABTestVariant.fromJson(Map<String, dynamic> json) {
    return ABTestVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      recipientCount: json['recipientCount'] as int,
      sentCount: json['sentCount'] as int,
      deliveredCount: json['deliveredCount'] as int,
      openedCount: json['openedCount'] as int,
      clickedCount: json['clickedCount'] as int,
      openRate: (json['openRate'] as num).toDouble(),
      clickRate: (json['clickRate'] as num).toDouble(),
      conversionRate: (json['conversionRate'] as num).toDouble(),
      isControl: json['isControl'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'body': body,
      'recipientCount': recipientCount,
      'sentCount': sentCount,
      'deliveredCount': deliveredCount,
      'openedCount': openedCount,
      'clickedCount': clickedCount,
      'openRate': openRate,
      'clickRate': clickRate,
      'conversionRate': conversionRate,
      'isControl': isControl,
    };
  }

  ABTestVariant copyWith({
    String? id,
    String? name,
    String? subject,
    String? body,
    int? recipientCount,
    int? sentCount,
    int? deliveredCount,
    int? openedCount,
    int? clickedCount,
    double? openRate,
    double? clickRate,
    double? conversionRate,
    bool? isControl,
  }) {
    return ABTestVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      recipientCount: recipientCount ?? this.recipientCount,
      sentCount: sentCount ?? this.sentCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      openedCount: openedCount ?? this.openedCount,
      clickedCount: clickedCount ?? this.clickedCount,
      openRate: openRate ?? this.openRate,
      clickRate: clickRate ?? this.clickRate,
      conversionRate: conversionRate ?? this.conversionRate,
      isControl: isControl ?? this.isControl,
    );
  }
}

/// A/B test status
enum ABTestStatus {
  draft,
  scheduled,
  running,
  paused,
  completed,
  cancelled,
}

/// A/B test results
class ABTestResults {
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalClicked;
  final double overallOpenRate;
  final double overallClickRate;
  final double overallConversionRate;
  final String winningVariantId;
  final double statisticalSignificance;
  final DateTime calculatedAt;
  final Map<String, dynamic> metrics;

  ABTestResults({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalOpened,
    required this.totalClicked,
    required this.overallOpenRate,
    required this.overallClickRate,
    required this.overallConversionRate,
    required this.winningVariantId,
    required this.statisticalSignificance,
    required this.calculatedAt,
    this.metrics = const {},
  });

  factory ABTestResults.fromJson(Map<String, dynamic> json) {
    return ABTestResults(
      totalSent: json['totalSent'] as int,
      totalDelivered: json['totalDelivered'] as int,
      totalOpened: json['totalOpened'] as int,
      totalClicked: json['totalClicked'] as int,
      overallOpenRate: (json['overallOpenRate'] as num).toDouble(),
      overallClickRate: (json['overallClickRate'] as num).toDouble(),
      overallConversionRate: (json['overallConversionRate'] as num).toDouble(),
      winningVariantId: json['winningVariantId'] as String,
      statisticalSignificance: (json['statisticalSignificance'] as num).toDouble(),
      calculatedAt: (json['calculatedAt'] as Timestamp).toDate(),
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSent': totalSent,
      'totalDelivered': totalDelivered,
      'totalOpened': totalOpened,
      'totalClicked': totalClicked,
      'overallOpenRate': overallOpenRate,
      'overallClickRate': overallClickRate,
      'overallConversionRate': overallConversionRate,
      'winningVariantId': winningVariantId,
      'statisticalSignificance': statisticalSignificance,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
      'metrics': metrics,
    };
  }
}

/// A/B test winner
class ABTestWinner {
  final String variantId;
  final String variantName;
  final String reason;
  final double improvementPercentage;
  final DateTime selectedAt;
  final String selectedBy;

  ABTestWinner({
    required this.variantId,
    required this.variantName,
    required this.reason,
    required this.improvementPercentage,
    required this.selectedAt,
    required this.selectedBy,
  });

  factory ABTestWinner.fromJson(Map<String, dynamic> json) {
    return ABTestWinner(
      variantId: json['variantId'] as String,
      variantName: json['variantName'] as String,
      reason: json['reason'] as String,
      improvementPercentage: (json['improvementPercentage'] as num).toDouble(),
      selectedAt: (json['selectedAt'] as Timestamp).toDate(),
      selectedBy: json['selectedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'variantName': variantName,
      'reason': reason,
      'improvementPercentage': improvementPercentage,
      'selectedAt': Timestamp.fromDate(selectedAt),
      'selectedBy': selectedBy,
    };
  }
}