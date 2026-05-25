import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user segments
class UserSegment {
  final String id;
  final String name;
  final String description;
  final SegmentType type;
  final List<SegmentRule> rules;
  final int userCount;
  final SegmentStatus status;
  final DateTime? lastCalculatedAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSegment({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rules,
    required this.userCount,
    required this.status,
    this.lastCalculatedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSegment.fromJson(Map<String, dynamic> json) {
    return UserSegment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SegmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SegmentType.custom,
      ),
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => SegmentRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userCount: json['userCount'] as int? ?? 0,
      status: SegmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SegmentStatus.active,
      ),
      lastCalculatedAt: json['lastCalculatedAt'] != null
          ? (json['lastCalculatedAt'] as Timestamp).toDate()
          : null,
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
      'type': type.name,
      'rules': rules.map((e) => e.toJson()).toList(),
      'userCount': userCount,
      'status': status.name,
      'lastCalculatedAt': lastCalculatedAt != null
          ? Timestamp.fromDate(lastCalculatedAt!)
          : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserSegment copyWith({
    String? id,
    String? name,
    String? description,
    SegmentType? type,
    List<SegmentRule>? rules,
    int? userCount,
    SegmentStatus? status,
    DateTime? lastCalculatedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSegment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rules: rules ?? this.rules,
      userCount: userCount ?? this.userCount,
      status: status ?? this.status,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == SegmentStatus.active;
  bool get isInactive => status == SegmentStatus.inactive;
  bool get isDynamic => type == SegmentType.dynamic;
  bool get isStatic => type == SegmentType.static;
}

enum SegmentType {
  static,
  dynamic,
  custom,
}

enum SegmentStatus {
  active,
  inactive,
  archived,
}

class SegmentRule {
  final String id;
  final String field;
  final SegmentOperator operator;
  final dynamic value;
  final String? description;

  SegmentRule({
    required this.id,
    required this.field,
    required this.operator,
    required this.value,
    this.description,
  });

  factory SegmentRule.fromJson(Map<String, dynamic> json) {
    return SegmentRule(
      id: json['id'] as String,
      field: json['field'] as String,
      operator: SegmentOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => SegmentOperator.equals,
      ),
      value: json['value'],
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field,
      'operator': operator.name,
      'value': value,
      'description': description,
    };
  }

  bool matches(Map<String, dynamic> userData) {
    final userValue = userData[field];

    switch (operator) {
      case SegmentOperator.equals:
        return userValue == value;
      case SegmentOperator.notEquals:
        return userValue != value;
      case SegmentOperator.contains:
        if (userValue is String && value is String) {
          return userValue.contains(value);
        }
        return false;
      case SegmentOperator.notContains:
        if (userValue is String && value is String) {
          return !userValue.contains(value);
        }
        return false;
      case SegmentOperator.greaterThan:
        if (userValue is num && value is num) {
          return userValue > value;
        }
        return false;
      case SegmentOperator.lessThan:
        if (userValue is num && value is num) {
          return userValue < value;
        }
        return false;
      case SegmentOperator.greaterThanOrEqual:
        if (userValue is num && value is num) {
          return userValue >= value;
        }
        return false;
      case SegmentOperator.lessThanOrEqual:
        if (userValue is num && value is num) {
          return userValue <= value;
        }
        return false;
      case SegmentOperator.isIn:
        if (value is List) {
          return value.contains(userValue);
        }
        return false;
      case SegmentOperator.notIn:
        if (value is List) {
          return !value.contains(userValue);
        }
        return false;
      case SegmentOperator.startsWith:
        if (userValue is String && value is String) {
          return userValue.startsWith(value);
        }
        return false;
      case SegmentOperator.endsWith:
        if (userValue is String && value is String) {
          return userValue.endsWith(value);
        }
        return false;
      case SegmentOperator.isNull:
        return userValue == null;
      case SegmentOperator.isNotNull:
        return userValue != null;
    }
  }
}

enum SegmentOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  isIn,
  notIn,
  startsWith,
  endsWith,
  isNull,
  isNotNull,
}

/// Model for segment membership
class SegmentMembership {
  final String id;
  final String segmentId;
  final String userId;
  final DateTime addedAt;
  final String? addedBy;
  final String? notes;

  SegmentMembership({
    required this.id,
    required this.segmentId,
    required this.userId,
    required this.addedAt,
    this.addedBy,
    this.notes,
  });

  factory SegmentMembership.fromJson(Map<String, dynamic> json) {
    return SegmentMembership(
      id: json['id'] as String,
      segmentId: json['segmentId'] as String,
      userId: json['userId'] as String,
      addedAt: (json['addedAt'] as Timestamp).toDate(),
      addedBy: json['addedBy'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'segmentId': segmentId,
      'userId': userId,
      'addedAt': Timestamp.fromDate(addedAt),
      'addedBy': addedBy,
      'notes': notes,
    };
  }
}

/// Model for segment analytics
class SegmentAnalytics {
  final String segmentId;
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> userDistribution;
  final DateTime calculatedAt;

  SegmentAnalytics({
    required this.segmentId,
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.userDistribution,
    required this.calculatedAt,
  });

  factory SegmentAnalytics.fromJson(Map<String, dynamic> json) {
    return SegmentAnalytics(
      segmentId: json['segmentId'] as String,
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      inactiveUsers: json['inactiveUsers'] as int,
      userDistribution: (json['userDistribution'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          {},
      calculatedAt: (json['calculatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segmentId': segmentId,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'userDistribution': userDistribution,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
    };
  }

  SegmentAnalytics copyWith({
    String? segmentId,
    int? totalUsers,
    int? activeUsers,
    int? inactiveUsers,
    Map<String, int>? userDistribution,
    DateTime? calculatedAt,
  }) {
    return SegmentAnalytics(
      segmentId: segmentId ?? this.segmentId,
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      inactiveUsers: inactiveUsers ?? this.inactiveUsers,
      userDistribution: userDistribution ?? this.userDistribution,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  double get activeRate =>
      totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;
}