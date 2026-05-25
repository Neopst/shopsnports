import 'package:cloud_firestore/cloud_firestore.dart';

/// API and third-party service settings
class APISettings {
  final String id;
  // Stripe integration
  final String? stripePublishableKey;
  final String? stripeSecretKey; // Encrypted
  final String? stripePlatformAccountId;

  // PayPal integration
  final String? paypalClientId;
  final String? paypalSecret; // Encrypted
  final String? paypalMode; // sandbox, live

  // AWS integration
  final String? awsAccessKeyId;
  final String? awsSecretKey; // Encrypted
  final String? awsRegion;
  final String? awsS3Bucket;

  // SendGrid (email service)
  final String? sendgridApiKey; // Encrypted
  final String? sendgridFromEmail;

  // SMTP Email Configuration
  final String? smtpHost;
  final int? smtpPort;
  final bool? smtpSecure; // true for SSL/TLS
  final String? smtpNoreplyEmail;
  final String? smtpNoreplyPassword; // Encrypted
  final String? smtpInvoiceEmail;
  final String? smtpInvoicePassword; // Encrypted

  // Twilio (SMS service)
  final String? twilioAccountSid;
  final String? twilioAuthToken; // Encrypted
  final String? twilioPhoneNumber;

  // Webhook configuration
  final Map<String, String> webhookSecrets; // Encrypted, for webhook validation

  // ElasticSearch/ECS
  final String? elasticsearchUrl;
  final String? elasticsearchApiKey; // Encrypted

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  APISettings({
    required this.id,
    this.stripePublishableKey,
    this.stripeSecretKey,
    this.stripePlatformAccountId,
    this.paypalClientId,
    this.paypalSecret,
    this.paypalMode,
    this.awsAccessKeyId,
    this.awsSecretKey,
    this.awsRegion,
    this.awsS3Bucket,
    this.sendgridApiKey,
    this.sendgridFromEmail,
    this.smtpHost,
    this.smtpPort,
    this.smtpSecure,
    this.smtpNoreplyEmail,
    this.smtpNoreplyPassword,
    this.smtpInvoiceEmail,
    this.smtpInvoicePassword,
    this.twilioAccountSid,
    this.twilioAuthToken,
    this.twilioPhoneNumber,
    required this.webhookSecrets,
    this.elasticsearchUrl,
    this.elasticsearchApiKey,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  APISettings copyWith({
    String? id,
    String? stripePublishableKey,
    String? stripeSecretKey,
    String? stripePlatformAccountId,
    String? paypalClientId,
    String? paypalSecret,
    String? paypalMode,
    String? awsAccessKeyId,
    String? awsSecretKey,
    String? awsRegion,
    String? awsS3Bucket,
    String? sendgridApiKey,
    String? sendgridFromEmail,
    String? smtpHost,
    int? smtpPort,
    bool? smtpSecure,
    String? smtpNoreplyEmail,
    String? smtpNoreplyPassword,
    String? smtpInvoiceEmail,
    String? smtpInvoicePassword,
    String? twilioAccountSid,
    String? twilioAuthToken,
    String? twilioPhoneNumber,
    Map<String, String>? webhookSecrets,
    String? elasticsearchUrl,
    String? elasticsearchApiKey,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
  }) {
    return APISettings(
      id: id ?? this.id,
      stripePublishableKey: stripePublishableKey ?? this.stripePublishableKey,
      stripeSecretKey: stripeSecretKey ?? this.stripeSecretKey,
      stripePlatformAccountId:
          stripePlatformAccountId ?? this.stripePlatformAccountId,
      paypalClientId: paypalClientId ?? this.paypalClientId,
      paypalSecret: paypalSecret ?? this.paypalSecret,
      paypalMode: paypalMode ?? this.paypalMode,
      awsAccessKeyId: awsAccessKeyId ?? this.awsAccessKeyId,
      awsSecretKey: awsSecretKey ?? this.awsSecretKey,
      awsRegion: awsRegion ?? this.awsRegion,
      awsS3Bucket: awsS3Bucket ?? this.awsS3Bucket,
      sendgridApiKey: sendgridApiKey ?? this.sendgridApiKey,
      sendgridFromEmail: sendgridFromEmail ?? this.sendgridFromEmail,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpSecure: smtpSecure ?? this.smtpSecure,
      smtpNoreplyEmail: smtpNoreplyEmail ?? this.smtpNoreplyEmail,
      smtpNoreplyPassword: smtpNoreplyPassword ?? this.smtpNoreplyPassword,
      smtpInvoiceEmail: smtpInvoiceEmail ?? this.smtpInvoiceEmail,
      smtpInvoicePassword: smtpInvoicePassword ?? this.smtpInvoicePassword,
      twilioAccountSid: twilioAccountSid ?? this.twilioAccountSid,
      twilioAuthToken: twilioAuthToken ?? this.twilioAuthToken,
      twilioPhoneNumber: twilioPhoneNumber ?? this.twilioPhoneNumber,
      webhookSecrets: webhookSecrets ?? this.webhookSecrets,
      elasticsearchUrl: elasticsearchUrl ?? this.elasticsearchUrl,
      elasticsearchApiKey: elasticsearchApiKey ?? this.elasticsearchApiKey,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stripePublishableKey': stripePublishableKey,
      'stripeSecretKey': stripeSecretKey,
      'stripePlatformAccountId': stripePlatformAccountId,
      'paypalClientId': paypalClientId,
      'paypalSecret': paypalSecret,
      'paypalMode': paypalMode,
      'awsAccessKeyId': awsAccessKeyId,
      'awsSecretKey': awsSecretKey,
      'awsRegion': awsRegion,
      'awsS3Bucket': awsS3Bucket,
      'sendgridApiKey': sendgridApiKey,
      'sendgridFromEmail': sendgridFromEmail,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'smtpSecure': smtpSecure,
      'smtpNoreplyEmail': smtpNoreplyEmail,
      'smtpNoreplyPassword': smtpNoreplyPassword,
      'smtpInvoiceEmail': smtpInvoiceEmail,
      'smtpInvoicePassword': smtpInvoicePassword,
      'twilioAccountSid': twilioAccountSid,
      'twilioAuthToken': twilioAuthToken,
      'twilioPhoneNumber': twilioPhoneNumber,
      'webhookSecrets': webhookSecrets,
      'elasticsearchUrl': elasticsearchUrl,
      'elasticsearchApiKey': elasticsearchApiKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'version': version,
    };
  }

  factory APISettings.fromMap(Map<String, dynamic> map) {
    return APISettings(
      id: map['id'] ?? 'api_settings',
      stripePublishableKey: map['stripePublishableKey'],
      stripeSecretKey: map['stripeSecretKey'],
      stripePlatformAccountId: map['stripePlatformAccountId'],
      paypalClientId: map['paypalClientId'],
      paypalSecret: map['paypalSecret'],
      paypalMode: map['paypalMode'],
      awsAccessKeyId: map['awsAccessKeyId'],
      awsSecretKey: map['awsSecretKey'],
      awsRegion: map['awsRegion'],
      awsS3Bucket: map['awsS3Bucket'],
      sendgridApiKey: map['sendgridApiKey'],
      sendgridFromEmail: map['sendgridFromEmail'],
      smtpHost: map['smtpHost'],
      smtpPort: map['smtpPort'],
      smtpSecure: map['smtpSecure'],
      smtpNoreplyEmail: map['smtpNoreplyEmail'],
      smtpNoreplyPassword: map['smtpNoreplyPassword'],
      smtpInvoiceEmail: map['smtpInvoiceEmail'],
      smtpInvoicePassword: map['smtpInvoicePassword'],
      twilioAccountSid: map['twilioAccountSid'],
      twilioAuthToken: map['twilioAuthToken'],
      twilioPhoneNumber: map['twilioPhoneNumber'],
      webhookSecrets: Map<String, String>.from(map['webhookSecrets'] ?? {}),
      elasticsearchUrl: map['elasticsearchUrl'],
      elasticsearchApiKey: map['elasticsearchApiKey'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? 'system',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] ?? 'system',
      version: map['version'] ?? 1,
    );
  }

  factory APISettings.empty() {
    final now = DateTime.now();
    return APISettings(
      id: 'api_settings',
      webhookSecrets: {},
      createdAt: now,
      createdBy: 'system',
      updatedAt: now,
      updatedBy: 'system',
      version: 1,
    );
  }

  @override
  String toString() => 'APISettings(id: $id, version: $version)';
}
