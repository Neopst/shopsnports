import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification deep linking
class NotificationDeepLink {
  final String id;
  final String name;
  final String description;
  final String linkUrl;
  final LinkType type;
  final String? route;
  final Map<String, dynamic>? parameters;
  final bool isActive;
  final int clickCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationDeepLink({
    required this.id,
    required this.name,
    required this.description,
    required this.linkUrl,
    required this.type,
    this.route,
    this.parameters,
    this.isActive = true,
    this.clickCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationDeepLink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationDeepLink(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      linkUrl: data['linkUrl'] ?? '',
      type: LinkType.fromString(data['type'] ?? 'default'),
      route: data['route'],
      parameters: data['parameters'] as Map<String, dynamic>?,
      isActive: data['isActive'] ?? true,
      clickCount: data['clickCount'] ?? 0,
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
      'linkUrl': linkUrl,
      'type': type.value,
      'route': route,
      'parameters': parameters,
      'isActive': isActive,
      'clickCount': clickCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  NotificationDeepLink copyWith({
    String? id,
    String? name,
    String? description,
    String? linkUrl,
    LinkType? type,
    String? route,
    Map<String, dynamic>? parameters,
    bool? isActive,
    int? clickCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationDeepLink(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      linkUrl: linkUrl ?? this.linkUrl,
      type: type ?? this.type,
      route: route ?? this.route,
      parameters: parameters ?? this.parameters,
      isActive: isActive ?? this.isActive,
      clickCount: clickCount ?? this.clickCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum LinkType {
  defaultLink('default'),
  product('product'),
  order('order'),
  invoice('invoice'),
  promotion('promotion'),
  profile('profile'),
  settings('settings'),
  custom('custom');

  final String value;
  const LinkType(this.value);

  static LinkType fromString(String value) {
    return LinkType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LinkType.defaultLink,
    );
  }
}