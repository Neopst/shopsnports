class NotificationTemplate {
  final int id;
  final String name;
  final String title;
  final String body;
  final String category;
  final String type;
  final bool isActive;
  final String? imageUrl;
  final String? actionUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
    required this.category,
    required this.type,
    this.isActive = true,
    this.imageUrl,
    this.actionUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'] as int,
      name: json['name'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'body': body,
      'category': category,
      'type': type,
      'is_active': isActive,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationTemplate copyWith({
    int? id,
    String? name,
    String? title,
    String? body,
    String? category,
    String? type,
    bool? isActive,
    String? imageUrl,
    String? actionUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
