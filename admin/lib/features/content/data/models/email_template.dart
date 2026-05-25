import 'package:cloud_firestore/cloud_firestore.dart';

enum EmailTemplateType {
  adminWelcome,
  adminInvitation,
  passwordReset,
  invoiceReminder,
  reviewApprovalNotice,
  systemAlert,
  affiliateWelcome,
  vendorWelcome,
  customerWelcome,
  // Shipping-related templates
  shippingRequestConfirmation,
  shippingStatusUpdate,
  shippingTrackingAssigned,
  newRegistration,
}

/// Email template model - for notification emails
class EmailTemplate {
  final String id;
  final String name; // e.g., "new-admin-welcome", "invoice-reminder"
  final String description;
  final String subject; // Email subject line
  final String htmlBody; // HTML email template
  final String plainTextBody; // Plain text fallback
  final Map<String, String>
  variables; // {{admin_name}}, {{password_reset_link}}
  final EmailTemplateType type;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  EmailTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.htmlBody,
    required this.plainTextBody,
    required this.variables,
    required this.type,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Replace template variables with actual values
  /// Example: replaceVariables({'admin_name': 'John', 'reset_link': 'https://...'})
  EmailTemplate withVariables(Map<String, String> values) {
    String subjectResult = subject;
    String htmlResult = htmlBody;
    String plainTextResult = plainTextBody;

    values.forEach((key, value) {
      subjectResult = subjectResult.replaceAll('{{$key}}', value);
      htmlResult = htmlResult.replaceAll('{{$key}}', value);
      plainTextResult = plainTextResult.replaceAll('{{$key}}', value);
    });

    return EmailTemplate(
      id: id,
      name: name,
      description: description,
      subject: subjectResult,
      htmlBody: htmlResult,
      plainTextBody: plainTextResult,
      variables: variables,
      type: type,
      isActive: isActive,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  EmailTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? subject,
    String? htmlBody,
    String? plainTextBody,
    Map<String, String>? variables,
    EmailTemplateType? type,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      plainTextBody: plainTextBody ?? this.plainTextBody,
      variables: variables ?? this.variables,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'htmlBody': htmlBody,
      'plainTextBody': plainTextBody,
      'variables': variables,
      'type': type.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory EmailTemplate.fromMap(Map<String, dynamic> map, String docId) {
    return EmailTemplate(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      htmlBody: map['htmlBody'] ?? '',
      plainTextBody: map['plainTextBody'] ?? '',
      variables: Map<String, String>.from(map['variables'] ?? {}),
      type: EmailTemplateType.values.byName(map['type'] ?? 'adminWelcome'),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? 'unknown',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] ?? 'unknown',
    );
  }

  factory EmailTemplate.empty() {
    final now = DateTime.now();
    return EmailTemplate(
      id: '',
      name: '',
      description: '',
      subject: '',
      htmlBody: '',
      plainTextBody: '',
      variables: {},
      type: EmailTemplateType.adminWelcome,
      isActive: true,
      createdAt: now,
      createdBy: '',
      updatedAt: now,
      updatedBy: '',
    );
  }

  @override
  String toString() => 'EmailTemplate(id: $id, name: $name, type: $type)';
}
