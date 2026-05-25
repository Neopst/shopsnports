class NotificationHistory {
  final int id;
  final int? templateId;
  final String title;
  final String body;
  final String category;
  final String targetUserType;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int sentCount;
  final int deliveredCount;
  final int failedCount;
  final int openedCount;
  final DateTime createdAt;

  NotificationHistory({
    required this.id,
    this.templateId,
    required this.title,
    required this.body,
    required this.category,
    required this.targetUserType,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.openedCount = 0,
    required this.createdAt,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'] as int,
      templateId: json['template_id'] as int?,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      targetUserType: json['target_user_type'] as String,
      status: json['status'] as String,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      sentCount: json['sent_count'] as int? ?? 0,
      deliveredCount: json['delivered_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      openedCount: json['opened_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  double get deliveryRate =>
      sentCount > 0 ? (deliveredCount / sentCount) * 100 : 0;
  double get openRate =>
      deliveredCount > 0 ? (openedCount / deliveredCount) * 100 : 0;
}
