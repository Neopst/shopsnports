import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// AffiliateApi - Uses Firebase as single source of truth for affiliate operations
/// Public URLs are stored in Firestore app_config collection
class AffiliateApi {
  final FirebaseFirestore _db;

  AffiliateApi._(this._db);

  factory AffiliateApi.withDb(FirebaseFirestore db) => AffiliateApi._(db);

  /// Get the public URL for the shipment form from Firestore config
  /// Falls back to a deep link scheme if no URL is configured
  Future<String> _getPublicBaseUrl() async {
    try {
      final configDoc = await _db.collection('app_config').doc('public_urls').get();
      if (configDoc.exists && configDoc.data()?['shipmentFormUrl'] != null) {
        return configDoc.data()!['shipmentFormUrl'] as String;
      }
    } catch (e) {
      AppLogger.error('Failed to fetch public URL config', e);
    }
    // Default to deep link scheme - update this if you have a web domain
    return 'myapp://';
  }

  Future<String> createShipmentLink({
    required String affiliateId,
    int expiresInHours = 24,
  }) async {
    final token = '${affiliateId}_${DateTime.now().millisecondsSinceEpoch}';
    final expiry = DateTime.now().add(Duration(hours: expiresInHours));

    await _db.collection('affiliate_shipment_tokens').doc(token).set({
      'affiliateId': affiliateId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiry),
    });

    // Get configurable public URL from Firestore
    final baseUrl = await _getPublicBaseUrl();
    return '$baseUrl/shipment-request?token=$token';
  }

  Future<Map<String, dynamic>> createShipmentOnBehalf({
    required String affiliateId,
    required Map<String, dynamic> client,
  }) async {
    final docRef = await _db.collection('shippingRequests').add({
      'affiliateId': affiliateId,
      'client': client,
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Get configurable public URL from Firestore
    final baseUrl = await _getPublicBaseUrl();

    return {
      'id': docRef.id,
      'link': '$baseUrl/shipment-request?id=${docRef.id}',
      'request': {
        'id': docRef.id,
        'affiliateId': affiliateId,
        'client': client,
      },
    };
  }
}
