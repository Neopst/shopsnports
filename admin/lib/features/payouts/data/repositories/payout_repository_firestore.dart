import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payout_models.dart';

class PayoutRepositoryFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String _payoutsCollection = 'payouts';
  static const String _commissionSettingsCollection = 'commission_settings';
  static const String _taxSettingsCollection = 'tax_settings';

  /// Get payouts stream with optional filters
  Stream<List<Payout>> getPayoutsStream({
    String? status,
    String? recipientType,
    String? recipientId,
  }) {
    Query query = _firestore.collection(_payoutsCollection);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (recipientType != null) {
      query = query.where('recipient_type', isEqualTo: recipientType);
    }
    if (recipientId != null) {
      query = query.where('recipient_id', isEqualTo: recipientId);
    }

    // Only order if no filters (to avoid index requirements)
    // Otherwise just fetch and sort in memory
    return query.snapshots().map((snapshot) {
      final payouts = snapshot.docs
          .map((doc) => Payout.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by created_at in memory
      payouts.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      return payouts;
    });
  }

  /// Get single payout by ID
  Future<Payout?> getPayoutById(String id) async {
    final doc = await _firestore.collection(_payoutsCollection).doc(id).get();
    if (!doc.exists) return null;
    return Payout.fromMap(doc.data()!);
  }

  /// Approve a payout
  Future<void> approvePayout(String payoutId, String approvedBy) async {
    await _firestore.collection(_payoutsCollection).doc(payoutId).update({
      'status': 'approved',
      'approved_by': approvedBy,
      'approved_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Process/complete a payout - Updates both payout and affiliate atomically
  Future<void> processPayout(
    String payoutId,
    String processedBy,
    String paymentReference,
  ) async {
    // Get payout details first
    final payout = await getPayoutById(payoutId);
    if (payout == null) {
      throw Exception('Payout not found: $payoutId');
    }

    // Validate payout can be processed
    if (payout.status != 'approved' && payout.status != 'pending') {
      throw Exception('Payout must be approved or pending to process');
    }

    // Use batch to update both records atomically
    final batch = _firestore.batch();

    // 1. Update payout status to completed
    final payoutRef = _firestore.collection(_payoutsCollection).doc(payoutId);
    batch.update(payoutRef, {
      'status': 'completed',
      'processed_by': processedBy,
      'processed_at': FieldValue.serverTimestamp(),
      'payment_reference': paymentReference,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 2. Update affiliate's pending payout balance (only for affiliate payouts)
    if (payout.recipientType == 'affiliate') {
      final affiliateRef = _firestore
          .collection('affiliates')
          .doc(payout.recipientId);
      batch.update(affiliateRef, {
        'pendingPayout': FieldValue.increment(-payout.netAmount),
        'lastPayoutDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Commit both updates atomically
    await batch.commit();
  }

  /// Cancel a payout
  Future<void> cancelPayout(String payoutId, String reason) async {
    await _firestore.collection(_payoutsCollection).doc(payoutId).update({
      'status': 'cancelled',
      'notes': reason,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get payout stats
  Future<Map<String, dynamic>> getPayoutStats() async {
    final snapshot = await _firestore.collection(_payoutsCollection).get();
    final payouts = snapshot.docs
        .map((doc) => Payout.fromMap(doc.data()))
        .toList();

    final pending = payouts.where((p) => p.status == 'pending').toList();
    final approved = payouts.where((p) => p.status == 'approved').toList();
    final completed = payouts.where((p) => p.status == 'completed').toList();

    final now = DateTime.now();
    final thisMonth = payouts
        .where(
          (p) =>
              p.processedAt != null &&
              p.processedAt!.year == now.year &&
              p.processedAt!.month == now.month,
        )
        .toList();

    return {
      'total_pending': pending.fold<double>(0, (sum, p) => sum + p.netAmount),
      'to_process_this_week': approved.fold<double>(
        0,
        (sum, p) => sum + p.netAmount,
      ),
      'paid_this_month': thisMonth.fold<double>(
        0,
        (sum, p) => sum + p.netAmount,
      ),
      'total_paid': completed.fold<double>(0, (sum, p) => sum + p.netAmount),
      'pending_count': pending.length,
      'approved_count': approved.length,
      'completed_count': completed.length,
    };
  }

  // ========== COMMISSION SETTINGS ==========

  /// Get commission settings stream
  Stream<List<CommissionSetting>> getCommissionSettingsStream() {
    return _firestore
        .collection(_commissionSettingsCollection)
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommissionSetting.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Get commission settings list
  Future<List<CommissionSetting>> getCommissionSettings() async {
    final snapshot = await _firestore
        .collection(_commissionSettingsCollection)
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommissionSetting.fromMap(doc.data()))
        .toList();
  }

  // ========== TAX SETTINGS ==========

  /// Get tax settings stream
  Stream<List<TaxSetting>> getTaxSettingsStream() {
    return _firestore
        .collection(_taxSettingsCollection)
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaxSetting.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Get tax settings list
  Future<List<TaxSetting>> getTaxSettings() async {
    final snapshot = await _firestore
        .collection(_taxSettingsCollection)
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => TaxSetting.fromMap(doc.data())).toList();
  }

  // ========== SAMPLE DATA SEEDING ==========

  /// Seed ONLY commission and tax settings (NO hardcoded payouts - use Firestore affiliates only)
  Future<void> seedSampleData() async {
    // Check if commission settings already exist
    final existingSettings = await _firestore
        .collection(_commissionSettingsCollection)
        .limit(1)
        .get();
    if (existingSettings.docs.isNotEmpty) {
      return; // Settings already seeded
    }

    final batch = _firestore.batch();

    // Sample commission settings - AFFILIATE AND SHIPPER ONLY (NO HARDCODED PAYOUTS)
    final commissionSettings = [
      {
        'id': 'comm_001',
        'entity_type': 'affiliate',
        'entity_id': null,
        'commission_type': 'percentage',
        'commission_value': 15.0, // Match the affiliate commission rate
        'min_amount': null,
        'max_amount': null,
        'effective_from': null,
        'effective_to': null,
        'is_active': true,
        'created_by': 'system',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'id': 'comm_002',
        'entity_type': 'shipper',
        'entity_id': null,
        'commission_type': 'percentage',
        'commission_value': 8.0,
        'min_amount': 1000.0,
        'max_amount': null,
        'effective_from': null,
        'effective_to': null,
        'is_active': true,
        'created_by': 'system',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final setting in commissionSettings) {
      batch.set(
        _firestore
            .collection(_commissionSettingsCollection)
            .doc(setting['id'] as String),
        setting,
      );
    }

    // Sample tax settings
    final taxSettings = [
      {
        'id': 'tax_001',
        'tax_name': 'VAT',
        'tax_type': 'vat',
        'tax_rate': 7.5,
        'applies_to': 'all',
        'country': 'Nigeria',
        'region': null,
        'effective_from': null,
        'effective_to': null,
        'is_active': true,
        'created_by': 'system',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tax_002',
        'tax_name': 'Withholding Tax',
        'tax_type': 'withholding',
        'tax_rate': 5.0,
        'applies_to': 'shippers',
        'country': 'Nigeria',
        'region': null,
        'effective_from': null,
        'effective_to': null,
        'is_active': true,
        'created_by': 'system',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final setting in taxSettings) {
      batch.set(
        _firestore
            .collection(_taxSettingsCollection)
            .doc(setting['id'] as String),
        setting,
      );
    }

    await batch.commit();
  }
}
