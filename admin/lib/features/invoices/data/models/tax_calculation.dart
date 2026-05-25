import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tax calculation records
class TaxCalculation {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final double subtotal;
  final double totalTax;
  final double totalAmount;
  final List<TaxItem> taxItems;
  final TaxCalculationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? calculatedBy;
  final String? notes;

  TaxCalculation({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.totalTax,
    required this.totalAmount,
    required this.taxItems,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.calculatedBy,
    this.notes,
  });

  factory TaxCalculation.fromJson(Map<String, dynamic> json) {
    return TaxCalculation(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      totalTax: (json['totalTax'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      taxItems: (json['taxItems'] as List<dynamic>?)
              ?.map((e) => TaxItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: TaxCalculationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaxCalculationStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      calculatedBy: json['calculatedBy'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'subtotal': subtotal,
      'totalTax': totalTax,
      'totalAmount': totalAmount,
      'taxItems': taxItems.map((e) => e.toJson()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'calculatedBy': calculatedBy,
      'notes': notes,
    };
  }

  TaxCalculation copyWith({
    String? id,
    String? invoiceId,
    String? invoiceNumber,
    double? subtotal,
    double? totalTax,
    double? totalAmount,
    List<TaxItem>? taxItems,
    TaxCalculationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? calculatedBy,
    String? notes,
  }) {
    return TaxCalculation(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      subtotal: subtotal ?? this.subtotal,
      totalTax: totalTax ?? this.totalTax,
      totalAmount: totalAmount ?? this.totalAmount,
      taxItems: taxItems ?? this.taxItems,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      calculatedBy: calculatedBy ?? this.calculatedBy,
      notes: notes ?? this.notes,
    );
  }

  double get effectiveTaxRate =>
      subtotal > 0 ? (totalTax / subtotal) * 100 : 0;
}

enum TaxCalculationStatus {
  pending,
  calculated,
  verified,
  filed,
  adjusted,
}

class TaxItem {
  final String id;
  final String name;
  final TaxType type;
  final double rate;
  final double amount;
  final bool isInclusive;
  final String? jurisdiction;
  final String? description;

  TaxItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rate,
    required this.amount,
    this.isInclusive = false,
    this.jurisdiction,
    this.description,
  });

  factory TaxItem.fromJson(Map<String, dynamic> json) {
    return TaxItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TaxType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaxType.sales,
      ),
      rate: (json['rate'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      isInclusive: json['isInclusive'] as bool? ?? false,
      jurisdiction: json['jurisdiction'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rate': rate,
      'amount': amount,
      'isInclusive': isInclusive,
      'jurisdiction': jurisdiction,
      'description': description,
    };
  }

  TaxItem copyWith({
    String? id,
    String? name,
    TaxType? type,
    double? rate,
    double? amount,
    bool? isInclusive,
    String? jurisdiction,
    String? description,
  }) {
    return TaxItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      isInclusive: isInclusive ?? this.isInclusive,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      description: description ?? this.description,
    );
  }
}

enum TaxType {
  sales,
  vat,
  gst,
  service,
  excise,
  customs,
  other,
}

/// Tax configuration for different jurisdictions
class TaxConfiguration {
  final String id;
  final String jurisdiction;
  final String countryCode;
  final List<TaxRule> rules;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaxConfiguration({
    required this.id,
    required this.jurisdiction,
    required this.countryCode,
    required this.rules,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaxConfiguration.fromJson(Map<String, dynamic> json) {
    return TaxConfiguration(
      id: json['id'] as String,
      jurisdiction: json['jurisdiction'] as String,
      countryCode: json['countryCode'] as String,
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => TaxRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jurisdiction': jurisdiction,
      'countryCode': countryCode,
      'rules': rules.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaxConfiguration copyWith({
    String? id,
    String? jurisdiction,
    String? countryCode,
    List<TaxRule>? rules,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxConfiguration(
      id: id ?? this.id,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      countryCode: countryCode ?? this.countryCode,
      rules: rules ?? this.rules,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TaxRule {
  final String id;
  final String name;
  final TaxType type;
  final double rate;
  final bool isInclusive;
  final List<String> applicableCategories;
  final double? minimumAmount;
  final double? maximumAmount;
  final String? description;

  TaxRule({
    required this.id,
    required this.name,
    required this.type,
    required this.rate,
    this.isInclusive = false,
    this.applicableCategories = const [],
    this.minimumAmount,
    this.maximumAmount,
    this.description,
  });

  factory TaxRule.fromJson(Map<String, dynamic> json) {
    return TaxRule(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TaxType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaxType.sales,
      ),
      rate: (json['rate'] as num).toDouble(),
      isInclusive: json['isInclusive'] as bool? ?? false,
      applicableCategories:
          (json['applicableCategories'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      minimumAmount: json['minimumAmount'] as double?,
      maximumAmount: json['maximumAmount'] as double?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rate': rate,
      'isInclusive': isInclusive,
      'applicableCategories': applicableCategories,
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
      'description': description,
    };
  }

  bool appliesTo(double amount, String category) {
    if (applicableCategories.isNotEmpty &&
        !applicableCategories.contains(category)) {
      return false;
    }
    if (minimumAmount != null && amount < minimumAmount!) {
      return false;
    }
    if (maximumAmount != null && amount > maximumAmount!) {
      return false;
    }
    return true;
  }
}