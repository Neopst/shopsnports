import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/affiliate.dart';
import '../models/shipping_request.dart';
import '../models/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import 'tax_calculation_service.dart';

/// Affiliate Service - Firestore-based implementation
///
/// Firebase is the single source of truth for all affiliate data
/// No AWS ECS backend - all data comes from Firestore
class AffiliateService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final AffiliateService _instance = AffiliateService._();
  factory AffiliateService() => _instance;
  AffiliateService._();

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Get current user's affiliate profile
  /// Returns null if user is not authenticated or profile doesn't exist.
  /// Logs errors for debugging.
  Future<Affiliate?> getAffiliateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('affiliates').doc(user.uid).get();
      if (doc.exists) {
        return Affiliate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get affiliate profile', e);
      return null;
    }
  }

  /// Get affiliate earnings summary
  /// Returns empty earnings on error (logs the error for debugging).
  Future<AffiliateEarnings> getEarnings() async {
    final user = _auth.currentUser;
    if (user == null) {
      return AffiliateEarnings.empty();
    }

    try {
      // Get affiliate document
      final affiliateDoc =
          await _db.collection('affiliates').doc(user.uid).get();

      if (!affiliateDoc.exists) {
        return AffiliateEarnings.empty();
      }

      final data = affiliateDoc.data()!;

      // Calculate this month's earnings from commissions
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final commissionsSnapshot = await _db
          .collection('commissions')
          .where('affiliateId', isEqualTo: user.uid)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double thisMonthEarnings = 0;
      int thisMonthShipments = 0;

      for (final doc in commissionsSnapshot.docs) {
        final commission = doc.data();
        thisMonthEarnings += (commission['commissionAmount'] as num).toDouble();
        thisMonthShipments++;
      }

      return AffiliateEarnings(
        totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        pendingPayout: (data['pendingPayout'] as num?)?.toDouble() ?? 0.0,
        thisMonthEarnings: thisMonthEarnings,
        totalShipments: data['totalShipments'] as int? ?? 0,
        thisMonthShipments: thisMonthShipments,
        averageCommission: (data['totalEarnings'] as num?)?.toDouble() ??
            0.0 / ((data['totalShipments'] as int?) ?? 1).clamp(1, 1000),
      );
    } catch (e) {
      AppLogger.error('Failed to get affiliate earnings', e);
      return AffiliateEarnings.empty();
    }
  }

  /// Get affiliated shipments (where this affiliate was tagged)
  /// Returns empty list on error (logs the error for debugging).
  Future<List<ShippingRequest>> getShipments({
    int page = 1,
    int pageSize = 20,
    ShippingStatus? status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('shippingRequests')
          .where('affiliateId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toJson());
      }

      final snapshot = await query.limit(pageSize).get();

      return snapshot.docs
          .map((doc) => ShippingRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get affiliate shipments', e);
      return [];
    }
  }

  /// Get details for a single shipment
  /// Returns null if not found or on error (logs the error for debugging).
  Future<ShippingRequest?> getShipment(String shipmentId) async {
    try {
      final doc =
          await _db.collection('shippingRequests').doc(shipmentId).get();
      if (!doc.exists) return null;
      return ShippingRequest.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get shipment: $shipmentId', e);
      return null;
    }
  }

  /// Search for shipments in-memory by ID, tracking number, or client fields.
  List<ShippingRequest> searchShipments(
    List<ShippingRequest> shipments,
    String query,
  ) {
    final normalized = query.toLowerCase();

    return shipments.where((shipment) {
      return shipment.id.toLowerCase().contains(normalized) ||
          (shipment.trackingNumber?.toLowerCase().contains(normalized) ??
              false) ||
          (shipment.clientName?.toLowerCase().contains(normalized) ?? false) ||
          (shipment.clientEmail?.toLowerCase().contains(normalized) ?? false);
    }).toList();
  }

  /// Stream of affiliated shipments (real-time updates)
  /// Returns empty stream on error (logs the error for debugging).
  Stream<List<ShippingRequest>> watchShipments({ShippingStatus? status}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _db
        .collection('shippingRequests')
        .where('affiliateId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toJson());
    }

    return query.snapshots().map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => ShippingRequest.fromFirestore(doc))
            .toList();
      } catch (e) {
        AppLogger.error('Failed to parse shipment documents', e);
        return <ShippingRequest>[];
      }
    });
  }

  /// Get payout history
  /// Returns empty list on error (logs the error for debugging).
  Future<List<Map<String, dynamic>>> getPayouts({
    int page = 1,
    int pageSize = 20,
    PayoutStatus? status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('payouts')
          .where('affiliateId', isEqualTo: user.uid)
          .orderBy('requestedAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.limit(pageSize).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get affiliate payouts', e);
      return [];
    }
  }

  /// Request a payout
  Future<Map<String, dynamic>> requestPayout({
    required double amount,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // ========== VALIDATION: Minimum Threshold ==========
    const MIN_PAYOUT_THRESHOLD = 10.0;
    if (amount < MIN_PAYOUT_THRESHOLD) {
      throw Exception(
        'Minimum payout amount is \$${MIN_PAYOUT_THRESHOLD.toStringAsFixed(2)}',
      );
    }

    try {
      // ========== VALIDATION: Check for pending payout requests ==========
      final pendingPayoutsSnapshot = await _db
          .collection('payouts')
          .where('affiliateId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingPayoutsSnapshot.docs.isNotEmpty) {
        throw Exception(
          'You already have a pending payout request. Please wait for it to be processed before requesting another.',
        );
      }

      // Get affiliate info
      final affiliateDoc =
          await _db.collection('affiliates').doc(user.uid).get();

      if (!affiliateDoc.exists) {
        throw Exception('Affiliate profile not found');
      }

      final affiliateData = affiliateDoc.data()!;

      // Get pending commissions for this affiliate
      final pendingCommissionsSnapshot = await _db
          .collection('commissions')
          .where('affiliateId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingCommissionsSnapshot.docs.isEmpty) {
        throw Exception('No pending commissions available for payout');
      }

      // ========== VALIDATION: Calculate total available ==========
      double totalAvailable = 0.0;
      for (final doc in pendingCommissionsSnapshot.docs) {
        final commission = doc.data();
        totalAvailable += (commission['commissionAmount'] as num).toDouble();
      }

      if (totalAvailable < amount) {
        throw Exception(
          'Insufficient pending commissions. Available: \$${totalAvailable.toStringAsFixed(2)}, Requested: \$${amount.toStringAsFixed(2)}',
        );
      }

      // Select commissions that sum up to the requested amount
      final List<String> selectedCommissionIds = [];
      double selectedAmount = 0.0;

      for (final doc in pendingCommissionsSnapshot.docs) {
        final commission = doc.data();
        final commissionAmount = (commission['commissionAmount'] as num).toDouble();

        if (selectedAmount + commissionAmount <= amount) {
          selectedCommissionIds.add(doc.id);
          selectedAmount += commissionAmount;
        }

        if (selectedAmount >= amount) {
          break;
        }
      }

      // Generate payout number: PAY-YYYYMMDD-XXXXX
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0].replaceAll('-', '');
      final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8).toUpperCase();
      final payoutNumber = 'PAY-$dateStr-$randomSuffix';

      // Calculate payout amounts
      final grossAmount = selectedAmount;
      final taxCalculationService = TaxCalculationService();
      final taxResult = await taxCalculationService.calculateTax(
        amount: selectedAmount,
        recipientType: 'affiliate',
      );
      final taxAmount = taxResult.taxAmount;
      final netAmount = grossAmount - taxAmount;

      // Create payout request
      final payoutRef = await _db.collection('payouts').add({
        'payoutNumber': payoutNumber,
        'recipientType': 'affiliate',
        'recipientId': user.uid,
        'recipientName': affiliateData['fullName'] ?? 'Unknown',
        'grossAmount': grossAmount,
        'commissionAmount': selectedAmount,
        'taxAmount': taxAmount,
        'netAmount': netAmount,
        'currency': 'USD',
        'affiliateId': user.uid,
        'affiliateName': affiliateData['fullName'] ?? 'Unknown',
        'affiliateEmail': affiliateData['email'],
        'amount': selectedAmount,
        'commissionIds': selectedCommissionIds,
        'status': 'pending',
        'bankAccountDetails': affiliateData['bankAccountDetails'],
        'period': now.toIso8601String().substring(0, 7),
        'periodStart': Timestamp.fromDate(now),
        'periodEnd': Timestamp.fromDate(now),
        'requestedAt': FieldValue.serverTimestamp(),
        'requestedBy': user.uid,
        'notes': notes ?? '',
        'paymentMethod': 'bank_transfer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark selected commissions as approved
      final batch = _db.batch();
      for (final commissionId in selectedCommissionIds) {
        batch.update(_db.collection('commissions').doc(commissionId), {
          'status': 'approved',
          'payoutId': payoutRef.id,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      return {
        'id': payoutRef.id,
        'payoutNumber': payoutNumber,
        'status': 'pending',
        'amount': selectedAmount,
        'commissionCount': selectedCommissionIds.length,
        'message': 'Payout request submitted successfully',
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Apply to become an affiliate
  Future<Affiliate> applyAsAffiliate({
    required String fullName,
    required String email,
    required String phone,
    String? companyName,
    required PayoutSchedule payoutSchedule,
    String? bankAccountDetails,
    String? taxId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final affiliateRef = _db.collection('affiliates').doc(user.uid);

      final affiliate = Affiliate(
        id: user.uid,
        userId: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        companyName: companyName,
        status: AffiliateStatus.pending,
        commissionRate: 15.0, // Default rate
        payoutSchedule: payoutSchedule,
        bankAccountDetails: bankAccountDetails,
        taxId: taxId,
        totalEarnings: 0.0,
        pendingPayout: 0.0,
        totalShipments: 0,
        joinedDate: DateTime.now(),
      );

      await affiliateRef.set(affiliate.toMap());

      return affiliate;
    } catch (e) {
      rethrow;
    }
  }

  /// Update affiliate profile
  Future<Affiliate> updateAffiliateProfile({
    String? fullName,
    String? phone,
    String? companyName,
    String? bankAccountDetails,
    PayoutSchedule? payoutSchedule,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final affiliateRef = _db.collection('affiliates').doc(user.uid);
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['fullName'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (companyName != null) updateData['companyName'] = companyName;
      if (bankAccountDetails != null) {
        updateData['bankAccountDetails'] = bankAccountDetails;
      }
      if (payoutSchedule != null) {
        updateData['payoutSchedule'] = payoutSchedule.name;
      }

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await affiliateRef.update(updateData);

      final doc = await affiliateRef.get();
      return Affiliate.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }
}

/// Affiliate Earnings Model
class AffiliateEarnings {
  final double totalEarnings;
  final double pendingPayout;
  final double thisMonthEarnings;
  final int totalShipments;
  final int thisMonthShipments;
  final double averageCommission;

  AffiliateEarnings({
    required this.totalEarnings,
    required this.pendingPayout,
    required this.thisMonthEarnings,
    required this.totalShipments,
    required this.thisMonthShipments,
    required this.averageCommission,
  });

  factory AffiliateEarnings.empty() {
    return AffiliateEarnings(
      totalEarnings: 0,
      pendingPayout: 0,
      thisMonthEarnings: 0,
      totalShipments: 0,
      thisMonthShipments: 0,
      averageCommission: 0,
    );
  }

  factory AffiliateEarnings.fromJson(Map<String, dynamic> json) {
    return AffiliateEarnings(
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      pendingPayout: (json['pendingPayout'] as num).toDouble(),
      thisMonthEarnings: (json['thisMonthEarnings'] as num).toDouble(),
      totalShipments: json['totalShipments'] as int,
      thisMonthShipments: json['thisMonthShipments'] as int,
      averageCommission: (json['averageCommission'] as num).toDouble(),
    );
  }
}
