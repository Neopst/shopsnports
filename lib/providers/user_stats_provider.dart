import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User statistics from Firestore
class UserStats {
  final int totalShipments;
  final int inTransit;
  final int delivered;
  final int pending;
  final double totalSpent;
  final double totalSaved;

  UserStats({
    required this.totalShipments,
    required this.inTransit,
    required this.delivered,
    required this.pending,
    required this.totalSpent,
    required this.totalSaved,
  });

  factory UserStats.empty() => UserStats(
        totalShipments: 0,
        inTransit: 0,
        delivered: 0,
        pending: 0,
        totalSpent: 0,
        totalSaved: 0,
      );
}

/// Provider for user shipping statistics
final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return UserStats.empty();

  final db = FirebaseFirestore.instance;

  try {
    // Get all shipments for this user
    final snapshot = await db
        .collection('shippingRequests')
        .where('requesterId', isEqualTo: user.uid)
        .get();

    int inTransit = 0;
    int delivered = 0;
    int pending = 0;
    double totalSpent = 0;
    double totalSaved = 0;

    for (final doc in snapshot.docs) {
      final status = doc.data()['status'] as String? ?? '';
      final actualCost = (doc.data()['actualCost'] as num?)?.toDouble() ?? 0;
      final estimatedCost = (doc.data()['estimatedCost'] as num?)?.toDouble() ?? 0;

      totalSpent += actualCost;
      totalSaved += (estimatedCost - actualCost).clamp(0, double.infinity);

      switch (status.toLowerCase()) {
        case 'in_transit':
        case 'intransit':
        case 'in-transit':
        case 'shipped':
        case 'on_the_way':
          inTransit++;
          break;
        case 'delivered':
        case 'complete':
        case 'completed':
          delivered++;
          break;
        case 'pending':
        case 'pending_approval':
        case 'awaiting_pickup':
          pending++;
          break;
      }
    }

    return UserStats(
      totalShipments: snapshot.docs.length,
      inTransit: inTransit,
      delivered: delivered,
      pending: pending,
      totalSpent: totalSpent,
      totalSaved: totalSaved,
    );
  } catch (e) {
    return UserStats.empty();
  }
});

/// Provider for user KPI data (alias for stats)
final userKpiProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final stats = await ref.watch(userStatsProvider.future);
  return {
    'shipmentsCount': stats.totalShipments,
    'inTransit': stats.inTransit,
    'delivered': stats.delivered,
    'pending': stats.pending,
    'totalSpent': stats.totalSpent,
    'totalSaved': stats.totalSaved,
  };
});
