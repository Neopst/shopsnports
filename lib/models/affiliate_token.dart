import 'package:cloud_firestore/cloud_firestore.dart';

/// Affiliate Token - Unique identifier for affiliate shipping requests
/// Allows admin to easily identify which requests are from affiliates
/// Format: example "SHOP-AFF-2026-001" (SHOP-AFF-YYYY-SEQUENCE)
class AffiliateToken {
  final String id;
  final String token; // Human-readable token: SHOP-AFF-2026-001
  final String affiliateId; // Link to affiliate
  final String shippingRequestId; // Link to shipping request
  final String affiliateName;
  final String affiliateEmail;
  final bool used; // true when assigned to request
  final DateTime createdAt;
  final DateTime? usedAt;

  AffiliateToken({
    required this.id,
    required this.token,
    required this.affiliateId,
    this.shippingRequestId = '',
    required this.affiliateName,
    required this.affiliateEmail,
    this.used = false,
    required this.createdAt,
    this.usedAt,
  });

  /// Create from Firestore document
  factory AffiliateToken.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AffiliateToken(
      id: doc.id,
      token: data['token'] ?? '',
      affiliateId: data['affiliateId'] ?? '',
      shippingRequestId: data['shippingRequestId'] ?? '',
      affiliateName: data['affiliateName'] ?? '',
      affiliateEmail: data['affiliateEmail'] ?? '',
      used: data['used'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      usedAt: data['usedAt'] != null
          ? (data['usedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'token': token,
      'affiliateId': affiliateId,
      'shippingRequestId': shippingRequestId,
      'affiliateName': affiliateName,
      'affiliateEmail': affiliateEmail,
      'used': used,
      'createdAt': Timestamp.fromDate(createdAt),
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }

  /// Get display status
  String get status => used ? 'Used' : 'Available';

  /// Check if token can be used
  bool get canUse => !used;
}
