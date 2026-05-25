import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/affiliate_model.dart';

class AffiliateRepositoryFirestore {
  final FirebaseFirestore _firestore;

  AffiliateRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _affiliatesCollection = 'affiliates';
  static const String _payoutsCollection = 'payouts';

  // ==================== AFFILIATE METHODS ====================

  /// Get all affiliates as stream (real-time updates)
  Stream<List<Affiliate>> getAffiliatesStream() {
    return _firestore
        .collection(_affiliatesCollection)
        .orderBy('joinedDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Affiliate.fromFirestore(doc)).toList(),
        );
  }

  /// Get all affiliates (one-time fetch)
  Future<List<Affiliate>> getAffiliates() async {
    try {
      final snapshot = await _firestore
          .collection(_affiliatesCollection)
          .orderBy('joinedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Affiliate.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch affiliates: $e');
    }
  }

  /// Get affiliate by ID
  Future<Affiliate?> getAffiliateById(String id) async {
    try {
      final doc = await _firestore
          .collection(_affiliatesCollection)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return Affiliate.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch affiliate: $e');
    }
  }

  /// Get affiliate by user ID (for mobile app users to see their affiliate profile)
  Future<Affiliate?> getAffiliateByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_affiliatesCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return Affiliate.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch affiliate by userId: $e');
    }
  }

  /// Create new affiliate (when user applies)
  Future<String> createAffiliate(Affiliate affiliate) async {
    try {
      final docRef = _firestore
          .collection(_affiliatesCollection)
          .doc(affiliate.id);
      await docRef.set(affiliate.toMap());
      return affiliate.id;
    } catch (e) {
      throw Exception('Failed to create affiliate: $e');
    }
  }

  /// Update affiliate details
  Future<void> updateAffiliate(Affiliate affiliate) async {
    try {
      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliate.id)
          .update(affiliate.toMap());
    } catch (e) {
      throw Exception('Failed to update affiliate: $e');
    }
  }

  /// Update affiliate status (admin approves/suspends)
  Future<void> updateAffiliateStatus(
    String affiliateId,
    AffiliateStatus status,
  ) async {
    try {
      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .update({
            'status': status.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update affiliate status: $e');
    }
  }

  /// Update affiliate commission rate (admin only)
  /// Validates that rate is between 0% and 100%
  Future<void> updateCommissionRate(String affiliateId, double rate) async {
    // Validate commission rate
    if (!Affiliate.isValidCommissionRate(rate)) {
      throw Exception(
        'Commission rate must be between ${Affiliate.minCommissionRate}% and ${Affiliate.maxCommissionRate}%. '
        'Provided: $rate%'
      );
    }

    try {
      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .update({
            'commissionRate': rate,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update commission rate: $e');
    }
  }

  /// Update affiliate banking details (affiliate self-service)
  Future<void> updateBankingDetails({
    required String affiliateId,
    required String bankAccountDetails,
    String? taxId,
  }) async {
    try {
      final updates = {
        'bankAccountDetails': bankAccountDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (taxId != null) updates['taxId'] = taxId;

      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update banking details: $e');
    }
  }

  /// Delete affiliate (super admin only)
  Future<void> deleteAffiliate(String id) async {
    try {
      await _firestore.collection(_affiliatesCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete affiliate: $e');
    }
  }

  /// Approve affiliate (admin only)
  Future<void> approveAffiliate(String affiliateId, String adminId) async {
    try {
      // First, get the affiliate to find the userId
      final affiliateDoc = await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .get();

      if (!affiliateDoc.exists) {
        throw Exception('Affiliate not found');
      }

      final affiliateData = affiliateDoc.data()!;
      final userId = affiliateData['userId'] as String?;

      // Use batch for atomic update
      final batch = _firestore.batch();

      // Update affiliates collection
      final affiliateRef = _firestore.collection(_affiliatesCollection).doc(affiliateId);
      batch.update(affiliateRef, {
        'status': AffiliateStatus.approved.name,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
        'rejectionReason': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update the user's affiliateApproved field if userId exists
      if (userId != null) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'affiliateApproved': true,
          'roleType': 'affiliate', // Ensure user role is set to affiliate
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve affiliate: $e');
    }
  }

  /// Reject affiliate (admin only)
  Future<void> rejectAffiliate(String affiliateId, String reason) async {
    try {
      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .update({
            'status': 'rejected', // Add rejected to enum
            'rejectionReason': reason,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to reject affiliate: $e');
    }
  }

  /// Suspend affiliate (admin only)
  Future<void> suspendAffiliate(String affiliateId, String reason) async {
    try {
      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .update({
            'status': AffiliateStatus.suspended.name,
            'suspensionReason': reason,
            'suspendedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to suspend affiliate: $e');
    }
  }

  /// Get affiliates by status
  Future<List<Affiliate>> getAffiliatesByStatus(AffiliateStatus status) async {
    try {
      final snapshot = await _firestore
          .collection(_affiliatesCollection)
          .where('status', isEqualTo: status.name)
          .orderBy('joinedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Affiliate.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch affiliates by status: $e');
    }
  }

  /// Increment affiliate earnings (called when shipment completed)
  Future<void> incrementEarnings({
    required String affiliateId,
    required double amount,
  }) async {
    try {
      await _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId)
          .update({
            'totalEarnings': FieldValue.increment(amount),
            'pendingPayout': FieldValue.increment(amount),
            'totalShipments': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to increment earnings: $e');
    }
  }

  // ==================== PAYOUT METHODS ====================

  /// Get all payouts as stream (real-time updates)
  Stream<List<PayoutRecord>> getPayoutsStream() {
    return _firestore
        .collection(_payoutsCollection)
        .orderBy('payoutDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PayoutRecord.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get all payouts (one-time fetch)
  Future<List<PayoutRecord>> getPayouts() async {
    try {
      final snapshot = await _firestore
          .collection(_payoutsCollection)
          .orderBy('payoutDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PayoutRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payouts: $e');
    }
  }

  /// Get payouts for specific affiliate
  Future<List<PayoutRecord>> getPayoutsByAffiliate(String affiliateId) async {
    try {
      final snapshot = await _firestore
          .collection(_payoutsCollection)
          .where('affiliateId', isEqualTo: affiliateId)
          .orderBy('payoutDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => PayoutRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payouts for affiliate: $e');
    }
  }

  /// Create payout record
  Future<String> createPayout(PayoutRecord payout) async {
    try {
      final docRef = _firestore.collection(_payoutsCollection).doc(payout.id);
      await docRef.set(payout.toMap());
      return payout.id;
    } catch (e) {
      throw Exception('Failed to create payout: $e');
    }
  }

  /// Process payout (mark as completed and update affiliate)
  Future<void> processPayout({
    required String payoutId,
    required String affiliateId,
    required double amount,
    required String transactionReference,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update payout status
      final payoutRef = _firestore.collection(_payoutsCollection).doc(payoutId);
      batch.update(payoutRef, {
        'status': PayoutStatus.completed.name,
        'transactionReference': transactionReference,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update affiliate's pending payout and last payout date
      final affiliateRef = _firestore
          .collection(_affiliatesCollection)
          .doc(affiliateId);
      batch.update(affiliateRef, {
        'pendingPayout': FieldValue.increment(-amount),
        'lastPayoutDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to process payout: $e');
    }
  }

  /// Update payout status
  Future<void> updatePayoutStatus(String payoutId, PayoutStatus status) async {
    try {
      await _firestore.collection(_payoutsCollection).doc(payoutId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update payout status: $e');
    }
  }

  // ==================== SHIPPING HISTORY ====================

  /// Get shipping requests for specific affiliate
  Future<List<Map<String, dynamic>>> getAffiliateShipments(
    String affiliateId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('shippingRequests')
          .where('affiliateId', isEqualTo: affiliateId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      throw Exception('Failed to fetch affiliate shipments: $e');
    }
  }

  /// Get affiliate earnings from delivered shipments
  Future<double> calculateAffiliateEarnings(String affiliateId) async {
    try {
      final snapshot = await _firestore
          .collection('shippingRequests')
          .where('affiliateId', isEqualTo: affiliateId)
          .where('status', isEqualTo: 'delivered')
          .get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final commissionAmount = doc.data()['commissionAmount'] ?? 0.0;
        total += commissionAmount;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate affiliate earnings: $e');
    }
  }

  // ==================== PAYOUT GENERATION ====================

  /// Generate payout for affiliate (admin-triggered)
  /// Finds all delivered shipments without payout and creates payout record
  Future<String?> generatePayoutForAffiliate(String affiliateId) async {
    try {
      // Get affiliate details
      final affiliate = await getAffiliateById(affiliateId);
      if (affiliate == null) throw Exception('Affiliate not found');

      // Get all delivered shipments without payout
      final shipmentsSnapshot = await _firestore
          .collection('shippingRequests')
          .where('affiliateId', isEqualTo: affiliateId)
          .where('status', isEqualTo: 'delivered')
          .where('payoutId', isEqualTo: null) // Not yet paid
          .get();

      if (shipmentsSnapshot.docs.isEmpty) {
        return null; // No unpaid shipments
      }

      // Calculate total commission
      double totalAmount = 0.0;
      final shipmentIds = <String>[];

      for (final doc in shipmentsSnapshot.docs) {
        final commissionAmount = (doc.data()['commissionAmount'] ?? 0.0)
            .toDouble();
        totalAmount += commissionAmount;
        shipmentIds.add(doc.id);
      }

      // Create payout record
      final payoutId = _firestore.collection(_payoutsCollection).doc().id;
      final payout = PayoutRecord(
        id: payoutId,
        affiliateId: affiliateId,
        affiliateName: affiliate.fullName,
        amount: totalAmount,
        taxAmount: 0.0, // Implement tax calculation if needed
        netAmount: totalAmount,
        period: '${DateTime.now().year}-${DateTime.now().month}',
        shipmentIds: shipmentIds,
        status: PayoutStatus.pending,
        payoutDate: DateTime.now(),
        notes: 'Auto-generated from ${shipmentIds.length} delivered shipments',
      );

      // Save payout
      await createPayout(payout);

      // Mark shipments as included in payout
      final batch = _firestore.batch();
      for (final shipmentId in shipmentIds) {
        final ref = _firestore.collection('shippingRequests').doc(shipmentId);
        batch.update(ref, {'payoutId': payoutId});
      }
      await batch.commit();

      return payoutId;
    } catch (e) {
      throw Exception('Failed to generate payout: $e');
    }
  }

  /// Get affiliate statistics (for dashboard)
  Future<Map<String, dynamic>> getAffiliateStats() async {
    try {
      final affiliatesSnapshot = await _firestore
          .collection(_affiliatesCollection)
          .get();
      final payoutsSnapshot = await _firestore
          .collection(_payoutsCollection)
          .get();

      final totalAffiliates = affiliatesSnapshot.docs.length;
      final approvedAffiliates = affiliatesSnapshot.docs
          .where((doc) => doc.data()['status'] == AffiliateStatus.approved.name)
          .length;
      final pendingAffiliates = affiliatesSnapshot.docs
          .where((doc) => doc.data()['status'] == AffiliateStatus.pending.name)
          .length;

      double totalEarnings = 0;
      double pendingPayouts = 0;
      for (final doc in affiliatesSnapshot.docs) {
        final data = doc.data();
        totalEarnings += (data['totalEarnings'] ?? 0).toDouble();
        pendingPayouts += (data['pendingPayout'] ?? 0).toDouble();
      }

      final completedPayouts = payoutsSnapshot.docs
          .where((doc) => doc.data()['status'] == PayoutStatus.completed.name)
          .length;

      double totalPaidOut = 0;
      for (final doc in payoutsSnapshot.docs) {
        if (doc.data()['status'] == PayoutStatus.completed.name) {
          totalPaidOut += (doc.data()['amount'] ?? 0).toDouble();
        }
      }

      return {
        'totalAffiliates': totalAffiliates,
        'approvedAffiliates': approvedAffiliates,
        'pendingAffiliates': pendingAffiliates,
        'totalEarnings': totalEarnings,
        'pendingPayouts': pendingPayouts,
        'totalPaidOut': totalPaidOut,
        'completedPayouts': completedPayouts,
      };
    } catch (e) {
      throw Exception('Failed to fetch affiliate stats: $e');
    }
  }
}
