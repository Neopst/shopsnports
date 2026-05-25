import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/models/shipping_request_simplified.dart';

/// Repository for shipping requests - handles Firestore queries
class ShippingRequestRepository {
  final FirebaseFirestore _db;

  ShippingRequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Query shipping request by tracking number
  /// Returns null if not found
  Future<ShippingRequestSimplified?> getByTrackingNumber(
      String trackingNumber) async {
    try {
      final query = await _db
          .collection('shippingRequests')
          .where('trackingNumber', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      return ShippingRequestSimplified.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's shipping requests
  Future<List<ShippingRequestSimplified>> getUserRequests(String userId) async {
    try {
      final query = await _db
          .collection('shippingRequests')
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ShippingRequestSimplified.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get affiliate's referral shipping requests
  Future<List<ShippingRequestSimplified>> getAffiliateRequests(
      String affiliateId) async {
    try {
      final query = await _db
          .collection('shippingRequests')
          .where('affiliateId', isEqualTo: affiliateId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ShippingRequestSimplified.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of user's shipping requests (real-time updates)
  Stream<List<ShippingRequestSimplified>> watchUserRequests(String userId) {
    return _db
        .collection('shippingRequests')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => ShippingRequestSimplified.fromFirestore(doc))
            .toList());
  }

  /// Stream single request by ID (for detail view)
  Stream<ShippingRequestSimplified?> watchRequest(String requestId) {
    return _db
        .collection('shippingRequests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return ShippingRequestSimplified.fromFirestore(doc);
    });
  }

  /// Get paginated user shipping requests
  /// Returns tuple of (requests, lastDoc) for next page cursor
  /// Set pageSize to control items per page (default 20)
  Future<({List<ShippingRequestSimplified> requests, DocumentSnapshot? lastDoc})>
      getUserRequestsPaginated(
    String userId, {
    DocumentSnapshot? startAfter,
    int pageSize = 20,
  }) async {
    try {
      Query query = _db
          .collection('shippingRequests')
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final requests = querySnapshot.docs
          .map((doc) => ShippingRequestSimplified.fromFirestore(doc))
          .toList();

      final lastDoc = querySnapshot.docs.isEmpty ? null : querySnapshot.docs.last;

      return (requests: requests, lastDoc: lastDoc);
    } catch (e) {
      rethrow;
    }
  }

  /// Get guest requests by email (for users who first submitted as guest)
  Future<List<ShippingRequestSimplified>> getGuestRequestsByEmail(
      String email) async {
    try {
      final query = await _db
          .collection('shippingRequests')
          .where('requesterId', isEqualTo: 'guest')
          .where('senderEmail', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ShippingRequestSimplified.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
