import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice discounts
class InvoiceDiscount {
  final String id;
  final String name;
  final String description;
  final DiscountType type;
  final double value;
  final String? currency;
  final DiscountApplication application;
  final bool isPercentage;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? minimumOrderAmount;
  final int? maximumDiscountAmount;
  final int? usageLimit;
  final int? usageCount;
  final List<String>? applicableProducts;
  final List<String>? applicableCategories;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InvoiceDiscount({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.currency,
    required this.application,
    this.isPercentage = false,
    this.isActive = true,
    this.validFrom,
    this.validUntil,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimit,
    this.usageCount = 0,
    this.applicableProducts,
    this.applicableCategories,
    required this.createdAt,
    this.updatedAt,
  });

  factory InvoiceDiscount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceDiscount(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: DiscountType.fromString(data['type'] ?? 'fixed'),
      value: (data['value'] ?? 0).toDouble(),
      currency: data['currency'],
      application: DiscountApplication.fromString(
          data['application'] ?? 'subtotal'),
      isPercentage: data['isPercentage'] ?? false,
      isActive: data['isActive'] ?? true,
      validFrom: data['validFrom'] != null
          ? (data['validFrom'] as Timestamp).toDate()
          : null,
      validUntil: data['validUntil'] != null
          ? (data['validUntil'] as Timestamp).toDate()
          : null,
      minimumOrderAmount: data['minimumOrderAmount'],
      maximumDiscountAmount: data['maximumDiscountAmount'],
      usageLimit: data['usageLimit'],
      usageCount: data['usageCount'] ?? 0,
      applicableProducts: data['applicableProducts'] != null
          ? List<String>.from(data['applicableProducts'])
          : null,
      applicableCategories: data['applicableCategories'] != null
          ? List<String>.from(data['applicableCategories'])
          : null,
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
      'value': value,
      'currency': currency,
      'application': application.value,
      'isPercentage': isPercentage,
      'isActive': isActive,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscountAmount': maximumDiscountAmount,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'applicableProducts': applicableProducts,
      'applicableCategories': applicableCategories,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (usageLimit != null && usageCount! >= usageLimit!) return false;
    return true;
  }

  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  bool get isNotStarted {
    if (validFrom == null) return false;
    return DateTime.now().isBefore(validFrom!);
  }

  bool get isUsageLimitReached {
    if (usageLimit == null) return false;
    return usageCount! >= usageLimit!;
  }

  double calculateDiscount(double subtotal) {
    double discount = 0;

    if (isPercentage) {
      discount = subtotal * (value / 100);
    } else {
      discount = value;
    }

    // Apply maximum discount limit
    if (maximumDiscountAmount != null && discount > maximumDiscountAmount!) {
      discount = maximumDiscountAmount!.toDouble();
    }

    return discount;
  }

  InvoiceDiscount copyWith({
    String? id,
    String? name,
    String? description,
    DiscountType? type,
    double? value,
    String? currency,
    DiscountApplication? application,
    bool? isPercentage,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
    int? minimumOrderAmount,
    int? maximumDiscountAmount,
    int? usageLimit,
    int? usageCount,
    List<String>? applicableProducts,
    List<String>? applicableCategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceDiscount(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      currency: currency ?? this.currency,
      application: application ?? this.application,
      isPercentage: isPercentage ?? this.isPercentage,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscountAmount: maximumDiscountAmount ?? this.maximumDiscountAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum DiscountType {
  fixed('fixed'),
  percentage('percentage'),
  buyXGetY('buyXGetY'),
  bulk('bulk'),
  tiered('tiered');

  final String value;
  const DiscountType(this.value);

  static DiscountType fromString(String value) {
    return DiscountType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DiscountType.fixed,
    );
  }
}

enum DiscountApplication {
  subtotal('subtotal'),
  total('total'),
  perItem('perItem'),
  shipping('shipping');

  final String value;
  const DiscountApplication(this.value);

  static DiscountApplication fromString(String value) {
    return DiscountApplication.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DiscountApplication.subtotal,
    );
  }
}