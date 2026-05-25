import 'package:cloud_firestore/cloud_firestore.dart';

class NewsTicker {
  final String id;
  final String text;
  final String? link;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? scheduledFor;
  final DateTime updatedAt;
  final String createdBy;
  final int viewCount;

  NewsTicker({
    required this.id,
    required this.text,
    this.link,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
    this.scheduledFor,
    required this.updatedAt,
    required this.createdBy,
    this.viewCount = 0,
  });

  NewsTicker copyWith({
    String? id,
    String? text,
    String? link,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? updatedAt,
    String? createdBy,
    int? viewCount,
  }) {
    return NewsTicker(
      id: id ?? this.id,
      text: text ?? this.text,
      link: link ?? this.link,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  /// Parse date from either Timestamp or String (handles Firestore data)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory NewsTicker.fromJson(Map<String, dynamic> json) {
    return NewsTicker(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      link: json['link'] as String?,
      priority: json['priority'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? _parseDateTime(json['expiresAt']) : null,
      updatedAt: _parseDateTime(json['updatedAt']),
      createdBy: json['createdBy'] as String? ?? 'admin',
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'link': link,
      'priority': priority,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'viewCount': viewCount,
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => isActive && !isExpired;
}
