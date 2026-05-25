import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice templates
class InvoiceTemplate {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String companyWebsite;
  final String taxId;
  final String bankName;
  final String bankAccountNumber;
  final String bankRoutingNumber;
  final String bankIban;
  final String bankSwift;
  final TemplateLayout layout;
  final TemplateColorScheme colorScheme;
  final List<TemplateSection> sections;
  final bool showLogo;
  final bool showCompanyInfo;
  final bool showBankDetails;
  final bool showTaxId;
  final bool showPaymentTerms;
  final String paymentTerms;
  final String notes;
  final String footer;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final int usageCount;
  final Map<String, dynamic> metadata;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl = '',
    this.companyName = '',
    this.companyAddress = '',
    this.companyPhone = '',
    this.companyEmail = '',
    this.companyWebsite = '',
    this.taxId = '',
    this.bankName = '',
    this.bankAccountNumber = '',
    this.bankRoutingNumber = '',
    this.bankIban = '',
    this.bankSwift = '',
    required this.layout,
    required this.colorScheme,
    required this.sections,
    this.showLogo = true,
    this.showCompanyInfo = true,
    this.showBankDetails = true,
    this.showTaxId = true,
    this.showPaymentTerms = true,
    this.paymentTerms = 'Net 30',
    this.notes = '',
    this.footer = '',
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.usageCount = 0,
    this.metadata = const {},
  });

  factory InvoiceTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceTemplate(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      logoUrl: data['logoUrl'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      companyAddress: data['companyAddress'] as String? ?? '',
      companyPhone: data['companyPhone'] as String? ?? '',
      companyEmail: data['companyEmail'] as String? ?? '',
      companyWebsite: data['companyWebsite'] as String? ?? '',
      taxId: data['taxId'] as String? ?? '',
      bankName: data['bankName'] as String? ?? '',
      bankAccountNumber: data['bankAccountNumber'] as String? ?? '',
      bankRoutingNumber: data['bankRoutingNumber'] as String? ?? '',
      bankIban: data['bankIban'] as String? ?? '',
      bankSwift: data['bankSwift'] as String? ?? '',
      layout: TemplateLayout.values.firstWhere(
        (e) => e.name == data['layout'],
        orElse: () => TemplateLayout.standard,
      ),
      colorScheme: TemplateColorScheme.values.firstWhere(
        (e) => e.name == data['colorScheme'],
        orElse: () => TemplateColorScheme.blue,
      ),
      sections: (data['sections'] as List)
          .map((s) => TemplateSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      showLogo: data['showLogo'] as bool? ?? true,
      showCompanyInfo: data['showCompanyInfo'] as bool? ?? true,
      showBankDetails: data['showBankDetails'] as bool? ?? true,
      showTaxId: data['showTaxId'] as bool? ?? true,
      showPaymentTerms: data['showPaymentTerms'] as bool? ?? true,
      paymentTerms: data['paymentTerms'] as String? ?? 'Net 30',
      notes: data['notes'] as String? ?? '',
      footer: data['footer'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] as String,
      updatedBy: data['updatedBy'] as String?,
      usageCount: data['usageCount'] as int? ?? 0,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'companyWebsite': companyWebsite,
      'taxId': taxId,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankRoutingNumber': bankRoutingNumber,
      'bankIban': bankIban,
      'bankSwift': bankSwift,
      'layout': layout.name,
      'colorScheme': colorScheme.name,
      'sections': sections.map((s) => s.toJson()).toList(),
      'showLogo': showLogo,
      'showCompanyInfo': showCompanyInfo,
      'showBankDetails': showBankDetails,
      'showTaxId': showTaxId,
      'showPaymentTerms': showPaymentTerms,
      'paymentTerms': paymentTerms,
      'notes': notes,
      'footer': footer,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'usageCount': usageCount,
      'metadata': metadata,
    };
  }

  InvoiceTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyWebsite,
    String? taxId,
    String? bankName,
    String? bankAccountNumber,
    String? bankRoutingNumber,
    String? bankIban,
    String? bankSwift,
    TemplateLayout? layout,
    TemplateColorScheme? colorScheme,
    List<TemplateSection>? sections,
    bool? showLogo,
    bool? showCompanyInfo,
    bool? showBankDetails,
    bool? showTaxId,
    bool? showPaymentTerms,
    String? paymentTerms,
    String? notes,
    String? footer,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    int? usageCount,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      taxId: taxId ?? this.taxId,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankRoutingNumber: bankRoutingNumber ?? this.bankRoutingNumber,
      bankIban: bankIban ?? this.bankIban,
      bankSwift: bankSwift ?? this.bankSwift,
      layout: layout ?? this.layout,
      colorScheme: colorScheme ?? this.colorScheme,
      sections: sections ?? this.sections,
      showLogo: showLogo ?? this.showLogo,
      showCompanyInfo: showCompanyInfo ?? this.showCompanyInfo,
      showBankDetails: showBankDetails ?? this.showBankDetails,
      showTaxId: showTaxId ?? this.showTaxId,
      showPaymentTerms: showPaymentTerms ?? this.showPaymentTerms,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      notes: notes ?? this.notes,
      footer: footer ?? this.footer,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      usageCount: usageCount ?? this.usageCount,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Template layout options
enum TemplateLayout {
  standard,
  modern,
  minimal,
  professional,
  creative,
}

/// Template color scheme options
enum TemplateColorScheme {
  blue,
  green,
  purple,
  red,
  orange,
  gray,
  dark,
  custom,
}

/// Template section
class TemplateSection {
  final String id;
  final String name;
  final SectionType type;
  final bool isVisible;
  final int order;
  final Map<String, dynamic> config;

  TemplateSection({
    required this.id,
    required this.name,
    required this.type,
    this.isVisible = true,
    required this.order,
    this.config = const {},
  });

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      id: json['id'] as String,
      name: json['name'] as String,
      type: SectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SectionType.header,
      ),
      isVisible: json['isVisible'] as bool? ?? true,
      order: json['order'] as int,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'isVisible': isVisible,
      'order': order,
      'config': config,
    };
  }

  TemplateSection copyWith({
    String? id,
    String? name,
    SectionType? type,
    bool? isVisible,
    int? order,
    Map<String, dynamic>? config,
  }) {
    return TemplateSection(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      config: config ?? this.config,
    );
  }
}

/// Section type
enum SectionType {
  header,
  companyInfo,
  customerInfo,
  lineItems,
  subtotal,
  tax,
  total,
  paymentInfo,
  bankDetails,
  notes,
  footer,
  terms,
  custom,
}