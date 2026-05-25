import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification badge management
class NotificationBadge {
  final String id;
  final String name;
  final String description;
  final BadgeType type;
  final String iconUrl;
  final String? color;
  final int? maxCount;
  final bool isActive;
  final int displayCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.iconUrl,
    this.color,
    this.maxCount,
    this.isActive = true,
    this.displayCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationBadge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: BadgeType.fromString(data['type'] ?? 'default'),
      iconUrl: data['iconUrl'] ?? '',
      color: data['color'],
      maxCount: data['maxCount'],
      isActive: data['isActive'] ?? true,
      displayCount: data['displayCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.value,
      'iconUrl': iconUrl,
      'color': color,
      'maxCount': maxCount,
      'isActive': isActive,
      'displayCount': displayCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  NotificationBadge copyWith({
    String? id,
    String? name,
    String? description,
    BadgeType? type,
    String? iconUrl,
    String? color,
    int? maxCount,
    bool? isActive,
    int? displayCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      iconUrl: iconUrl ?? this.iconUrl,
      color: color ?? this.color,
      maxCount: maxCount ?? this.maxCount,
      isActive: isActive ?? this.isActive,
      displayCount: displayCount ?? this.displayCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum BadgeType {
  defaultBadge('default'),
  notification('notification'),
  message('message'),
  alert('alert'),
  promotional('promotional'),
  system('system'),
  custom('custom');

  final String value;
  const BadgeType(this.value);

  static BadgeType fromString(String value) {
    return BadgeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BadgeType.defaultBadge,
    );
  }
}