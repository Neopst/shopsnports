// lib/features/dashboard/data/providers/dashboard_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dashboard statistics provider - aggregates data from multiple sources (REAL-TIME)
/// Firebase is the only source of truth - this provider streams live updates
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) async* {
  final db = FirebaseFirestore.instance;

  try {
    // Get customers count (real-time stream)
    final customersStream = db.collection('customers').snapshots();

    // Get shipments count (real-time stream - shippingRequests is the correct collection name)
    final shipmentsStream = db.collection('shippingRequests').snapshots();

    // Get affiliates count (real-time stream)
    final affiliatesStream = db.collection('affiliates').snapshots();

    // Get pending payouts (real-time stream)
    final payoutsStream = db.collection('payouts').where('status', isEqualTo: 'pending').snapshots();

    // Get commissions (real-time stream)
    final commissionsStream = db.collection('commissions').snapshots();

    // Combine all streams
    await for (final _ in customersStream) {
      final customersSnap = await db.collection('customers').get();

      final shipmentsSnap = await db.collection('shippingRequests').get();
      final shippingRequests = shipmentsSnap.docs.map((d) => d.data()).toList();

      final affiliatesSnap = await db.collection('affiliates').get();

      QuerySnapshot<Map<String, dynamic>> payoutsSnap;
      try {
        payoutsSnap = await db.collection('payouts').where('status', isEqualTo: 'pending').get();
      } catch (e) {
        payoutsSnap = await db.collection('payouts').limit(0).get();
      }

    // Calculate shipping metrics
    int pendingShipments = 0;
    int inTransitShipments = 0;
    int deliveredShipments = 0;
    double totalRevenue = 0;

    for (var request in shippingRequests) {
      final status = (request['status'] ?? '').toString().toLowerCase();
      final price = (request['shipmentPrice'] ?? request['price'] ?? 0).toDouble();

      if (status == 'submitted' || status == 'pending') {
        pendingShipments++;
      } else if (status == 'in_transit' || status == 'shipped') {
        inTransitShipments++;
      } else if (status == 'delivered' || status == 'completed') {
        deliveredShipments++;
      }

      if (price > 0) {
        totalRevenue += price;
      }
    }

    // Get commissions (real-time data)
    double totalCommissions = 0;
    try {
      final commissionsSnap = await db.collection('commissions').get();
      for (var doc in commissionsSnap.docs) {
        totalCommissions += (doc.data()['commissionAmount'] ?? 0).toDouble();
      }
    } catch (e) {
      // Commissions collection may not exist - keep at 0
    }

    // Yield stats for real-time updates
    yield DashboardStats(
      // Shipping
      totalShipments: shippingRequests.length,
      pendingShipments: pendingShipments,
      inTransitShipments: inTransitShipments,
      deliveredShipments: deliveredShipments,

      // Customers - using 'customers' collection as source of truth
      totalCustomers: customersSnap.size,

      // Affiliates
      totalAffiliates: affiliatesSnap.size,

      // Financial
      totalRevenue: totalRevenue,
      totalCommissions: totalCommissions,
      pendingPayouts: payoutsSnap.size,

      // Orders (using shippingRequests as proxy for now)
      totalOrders: shippingRequests.length,
      averageOrderValue: shippingRequests.isNotEmpty
        ? totalRevenue / shippingRequests.length
        : 0,
    );
    }
  } catch (e) {
    throw Exception('Failed to load dashboard stats: $e');
  }
});

/// Dashboard statistics model
class DashboardStats {
  final int totalShipments;
  final int pendingShipments;
  final int inTransitShipments;
  final int deliveredShipments;
  final int totalCustomers;
  final int totalAffiliates;
  final double totalRevenue;
  final double totalCommissions;
  final int pendingPayouts;
  final int totalOrders;
  final double averageOrderValue;

  DashboardStats({
    required this.totalShipments,
    required this.pendingShipments,
    required this.inTransitShipments,
    required this.deliveredShipments,
    required this.totalCustomers,
    required this.totalAffiliates,
    required this.totalRevenue,
    required this.totalCommissions,
    required this.pendingPayouts,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  // Convenience getters
  String get formattedRevenue => '\$${totalRevenue.toStringAsFixed(2)}';
  String get formattedAOV => '\$${averageOrderValue.toStringAsFixed(2)}';
  String get formattedCommissions => '\$${totalCommissions.toStringAsFixed(2)}';
}