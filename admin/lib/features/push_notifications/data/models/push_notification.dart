class PushNotification {
  final String title;
  final String body;
  final String category;
  final String targetUserType;
  final int? templateId;
  final List<int>? userIds;
  final DateTime? scheduledAt;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic>? customData;

  PushNotification({
    required this.title,
    required this.body,
    required this.category,
    required this.targetUserType,
    this.templateId,
    this.userIds,
    this.scheduledAt,
    this.imageUrl,
    this.actionUrl,
    this.customData,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'targetUserType': targetUserType,
      if (templateId != null) 'templateId': templateId,
      if (userIds != null && userIds!.isNotEmpty) 'userIds': userIds,
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (customData != null) 'data': customData,
    };
  }
}
