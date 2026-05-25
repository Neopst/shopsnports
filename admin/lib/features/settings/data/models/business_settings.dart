import 'package:cloud_firestore/cloud_firestore.dart';

/// Shipping zone configuration
class ShippingZone {
  final String id;
  final String name; // "Lagos & Surroundings", "Northern Nigeria"
  final List<String> regions; // ["Lagos Island", "Ikeja", "Lekki"]
  final double shippingRate; // Flat rate for this zone
  final bool isActive;

  ShippingZone({
    required this.id,
    required this.name,
    required this.regions,
    required this.shippingRate,
    required this.isActive,
  });

  // Legacy support for old field names
  List<String> get countries => regions;
  double get baseShippingCost => shippingRate;
  bool get isFreeShippingEnabled => false;
  double get freeShippingThreshold => 0.0;
  DateTime get createdAt => DateTime.now();

  ShippingZone copyWith({
    String? id,
    String? name,
    List<String>? regions,
    double? shippingRate,
    bool? isActive,
  }) {
    return ShippingZone(
      id: id ?? this.id,
      name: name ?? this.name,
      regions: regions ?? this.regions,
      shippingRate: shippingRate ?? this.shippingRate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'regions': regions,
      'shippingRate': shippingRate,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory ShippingZone.fromMap(Map<String, dynamic> map, String id) {
    return ShippingZone(
      id: id,
      name: map['name'] ?? '',
      regions: List<String>.from(map['regions'] ?? map['countries'] ?? []),
      shippingRate: (map['shippingRate'] ?? map['baseShippingCost'] ?? 0.0)
          .toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}

/// Payment method configuration
class PaymentMethod {
  final String id;
  final String name; // "Stripe", "Paystack", "Flutterwave"
  final String type; // Stripe, Paystack, Flutterwave
  final bool isEnabled;
  final bool isDefault;
  final String? apiKey; // Public/Publishable key
  final String? secretKey; // Secret key (encrypted in production)
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    required this.isDefault,
    this.apiKey,
    this.secretKey,
    required this.createdAt,
  });

  PaymentMethod copyWith({
    String? id,
    String? name,
    String? type,
    bool? isEnabled,
    bool? isDefault,
    String? apiKey,
    String? secretKey,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
      apiKey: apiKey ?? this.apiKey,
      secretKey: secretKey ?? this.secretKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isEnabled': isEnabled,
      'isDefault': isDefault,
      'apiKey': apiKey,
      'secretKey': secretKey, // TODO: Encrypt before storing
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map, String id) {
    return PaymentMethod(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      isEnabled: map['isEnabled'] ?? false,
      isDefault: map['isDefault'] ?? false,
      apiKey: map['apiKey'],
      secretKey: map['secretKey'], // TODO: Decrypt after retrieving
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Business settings - global configuration
class BusinessSettings {
  final String id;
  final String businessName;
  final String businessLogo; // URL
  final String businessEmail;
  final String businessPhone;
  final String? businessAddress;
  final String businessWebsite;
  final String supportEmail;
  final String? taxId;
  final double? taxRate; // e.g., 0.08 for 8%
  final String? currency; // USD, EUR, etc.
  final List<ShippingZone> shippingZones;
  final List<PaymentMethod> paymentMethods;
  final bool enableInvoices;
  final bool enableAffiliates;
  final bool enableShipping;
  final int version; // For version history
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  BusinessSettings({
    required this.id,
    required this.businessName,
    required this.businessLogo,
    required this.businessEmail,
    required this.businessPhone,
    this.businessAddress,
    required this.businessWebsite,
    required this.supportEmail,
    this.taxId,
    this.taxRate,
    this.currency,
    required this.shippingZones,
    required this.paymentMethods,
    required this.enableInvoices,
    required this.enableAffiliates,
    required this.enableShipping,
    required this.version,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  BusinessSettings copyWith({
    String? id,
    String? businessName,
    String? businessLogo,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? businessWebsite,
    String? supportEmail,
    String? taxId,
    double? taxRate,
    String? currency,
    List<ShippingZone>? shippingZones,
    List<PaymentMethod>? paymentMethods,
    bool? enableInvoices,
    bool? enableAffiliates,
    bool? enableShipping,
    int? version,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return BusinessSettings(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessLogo: businessLogo ?? this.businessLogo,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      businessWebsite: businessWebsite ?? this.businessWebsite,
      supportEmail: supportEmail ?? this.supportEmail,
      taxId: taxId ?? this.taxId,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
      shippingZones: shippingZones ?? this.shippingZones,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      enableInvoices: enableInvoices ?? this.enableInvoices,
      enableAffiliates: enableAffiliates ?? this.enableAffiliates,
      enableShipping: enableShipping ?? this.enableShipping,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'businessAddress': businessAddress,
      'businessWebsite': businessWebsite,
      'supportEmail': supportEmail,
      'taxId': taxId,
      'taxRate': taxRate,
      'currency': currency,
      'shippingZones': shippingZones.map((z) => z.toMap()).toList(),
      'paymentMethods': paymentMethods.map((m) => m.toMap()).toList(),
      'enableInvoices': enableInvoices,
      'enableAffiliates': enableAffiliates,
      'enableShipping': enableShipping,
      'version': version,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      id: map['id'] ?? 'business_settings',
      businessName: map['businessName'] ?? '',
      businessLogo: map['businessLogo'] ?? '',
      businessEmail: map['businessEmail'] ?? '',
      businessPhone: map['businessPhone'] ?? '',
      businessAddress: map['businessAddress'],
      businessWebsite: map['businessWebsite'] ?? '',
      supportEmail: map['supportEmail'] ?? '',
      taxId: map['taxId'],
      taxRate: (map['taxRate'] as num?)?.toDouble(),
      currency: map['currency'],
      shippingZones: ((map['shippingZones'] as List?) ?? [])
          .map((z) => ShippingZone.fromMap(z as Map<String, dynamic>, z['id']))
          .toList(),
      paymentMethods: ((map['paymentMethods'] as List?) ?? [])
          .map((m) => PaymentMethod.fromMap(m as Map<String, dynamic>, m['id']))
          .toList(),
      enableInvoices: map['enableInvoices'] ?? false,
      enableAffiliates: map['enableAffiliates'] ?? false,
      enableShipping: map['enableShipping'] ?? false,
      version: map['version'] ?? 1,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? 'system',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? 'system',
    );
  }

  factory BusinessSettings.defaults() {
    final now = DateTime.now();
    return BusinessSettings(
      id: 'business_settings',
      businessName: 'My Business',
      businessLogo: '',
      businessEmail: 'info@example.com',
      businessPhone: '+1-800-000-0000',
      businessWebsite: 'https://example.com',
      supportEmail: 'support@example.com',
      currency: 'USD',
      shippingZones: [],
      paymentMethods: [],
      enableInvoices: true,
      enableAffiliates: false,
      enableShipping: true,
      version: 1,
      createdAt: now,
      createdBy: 'system',
      updatedAt: now,
      updatedBy: 'system',
    );
  }

  @override
  String toString() =>
      'BusinessSettings(name: $businessName, version: $version, currency: $currency)';
}
