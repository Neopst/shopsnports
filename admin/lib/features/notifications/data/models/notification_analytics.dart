import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationAnalytics {
  final String id;
  final DateTime date;
  final int totalSent;
  final int delivered;
  final int opened;
  final int clicked;
  final int failed;
  final Map<String, int> byType;
  final Map<String, int> byCategory;

  NotificationAnalytics({
    required this.id,
    required this.date,
    required this.totalSent,
    required this.delivered,
    required this.opened,
    required this.clicked,
    required this.failed,
    required this.byType,
    required this.byCategory,
  });

  double get deliveryRate {
    if (totalSent == 0) return 0.0;
    return (delivered / totalSent) * 100;
  }

  double get openRate {
    if (delivered == 0) return 0.0;
    return (opened / delivered) * 100;
  }

  double get clickRate {
    if (opened == 0) return 0.0;
    return (clicked / opened) * 100;
  }

  double get failureRate {
    if (totalSent == 0) return 0.0;
    return (failed / totalSent) * 100;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': Timestamp.fromDate(date),
    'totalSent': totalSent,
    'delivered': delivered,
    'opened': opened,
    'clicked': clicked,
    'failed': failed,
    'byType': byType,
    'byCategory': byCategory,
  };

  factory NotificationAnalytics.fromMap(Map<String, dynamic> m) {
    return NotificationAnalytics(
      id: m['id'] ?? '',
      date: (m['date'] as Timestamp).toDate(),
      totalSent: m['totalSent'] ?? 0,
      delivered: m['delivered'] ?? 0,
      opened: m['opened'] ?? 0,
      clicked: m['clicked'] ?? 0,
      failed: m['failed'] ?? 0,
      byType: Map<String, int>.from(m['byType'] ?? {}),
      byCategory: Map<String, int>.from(m['byCategory'] ?? {}),
    );
  }

  NotificationAnalytics copyWith({
    String? id,
    DateTime? date,
    int? totalSent,
    int? delivered,
    int? opened,
    int? clicked,
    int? failed,
    Map<String, int>? byType,
    Map<String, int>? byCategory,
  }) {
    return NotificationAnalytics(
      id: id ?? this.id,
      date: date ?? this.date,
      totalSent: totalSent ?? this.totalSent,
      delivered: delivered ?? this.delivered,
      opened: opened ?? this.opened,
      clicked: clicked ?? this.clicked,
      failed: failed ?? this.failed,
      byType: byType ?? this.byType,
      byCategory: byCategory ?? this.byCategory,
    );
  }
}

class NotificationMetrics {
  final int totalSent;
  final int delivered;
  final int opened;
  final int clicked;
  final int failed;
  final double deliveryRate;
  final double openRate;
  final double clickRate;
  final double failureRate;
  final Map<String, int> byType;
  final Map<String, int> byCategory;
  final List<NotificationAnalytics> dailyStats;

  NotificationMetrics({
    required this.totalSent,
    required this.delivered,
    required this.opened,
    required this.clicked,
    required this.failed,
    required this.deliveryRate,
    required this.openRate,
    required this.clickRate,
    required this.failureRate,
    required this.byType,
    required this.byCategory,
    required this.dailyStats,
  });

  factory NotificationMetrics.fromAnalytics(List<NotificationAnalytics> analytics) {
    final totalSent = analytics.fold(0, (sum, a) => sum + a.totalSent);
    final delivered = analytics.fold(0, (sum, a) => sum + a.delivered);
    final opened = analytics.fold(0, (sum, a) => sum + a.opened);
    final clicked = analytics.fold(0, (sum, a) => sum + a.clicked);
    final failed = analytics.fold(0, (sum, a) => sum + a.failed);

    final byType = <String, int>{};
    final byCategory = <String, int>{};

    for (final a in analytics) {
      a.byType.forEach((key, value) {
        byType[key] = (byType[key] ?? 0) + value;
      });
      a.byCategory.forEach((key, value) {
        byCategory[key] = (byCategory[key] ?? 0) + value;
      });
    }

    return NotificationMetrics(
      totalSent: totalSent,
      delivered: delivered,
      opened: opened,
      clicked: clicked,
      failed: failed,
      deliveryRate: totalSent > 0 ? (delivered / totalSent) * 100 : 0,
      openRate: delivered > 0 ? (opened / delivered) * 100 : 0,
      clickRate: opened > 0 ? (clicked / opened) * 100 : 0,
      failureRate: totalSent > 0 ? (failed / totalSent) * 100 : 0,
      byType: byType,
      byCategory: byCategory,
      dailyStats: analytics,
    );
  }
}