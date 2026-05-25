import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed API client - now aggregating from Firestore collections

/// Dashboard stats provider - aggregates from Firestore (using shippingRequests as source of truth)
final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final firestore = FirebaseFirestore.instance;

    // Aggregate from multiple collections
    final customersSnapshot = await firestore.collection('customers').get();
    final shipmentsSnapshot = await firestore.collection('shippingRequests').get();
    final affiliatesSnapshot = await firestore.collection('affiliates').get();
    final invoicesSnapshot = await firestore.collection('invoices').get();

    // Calculate metrics
    int totalCustomers = customersSnapshot.size;
    int activeCustomers = customersSnapshot.docs
        .where((doc) => doc.data()['status'] == 'active')
        .length;

    int totalShipments = shipmentsSnapshot.size;
    int pendingShipments = shipmentsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'pending')
        .length;
    int inTransitShipments = shipmentsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'in_transit')
        .length;
    int deliveredShipments = shipmentsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'delivered')
        .length;

    int totalAffiliates = affiliatesSnapshot.size;
    int activeAffiliates = affiliatesSnapshot.docs
        .where((doc) => doc.data()['status'] == 'approved')
        .length;

    double totalRevenue = shipmentsSnapshot.docs.fold(0.0, (sum, doc) {
      return sum + ((doc.data()['estimatedCost'] ?? 0.0) as num).toDouble();
    });

    double totalEarnings = affiliatesSnapshot.docs.fold(0.0, (sum, doc) {
      return sum + ((doc.data()['totalEarnings'] ?? 0.0) as num).toDouble();
    });

    return {
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'newCustomersThisMonth': totalCustomers, // Simplified for now
      'totalShipments': totalShipments,
      'pendingShipments': pendingShipments,
      'inTransitShipments': inTransitShipments,
      'deliveredShipments': deliveredShipments,
      'totalAffiliates': totalAffiliates,
      'activeAffiliates': activeAffiliates,
      'totalRevenue': totalRevenue,
      'totalEarnings': totalEarnings,
      'totalInvoices': invoicesSnapshot.size,
    };
  },
);

/// Sales trends provider - aggregates shippingRequests by period
final salesTrendsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, period) async {
      final firestore = FirebaseFirestore.instance;

      // Get shippingRequests from last 30 days for monthly view
      final daysAgo = period == 'week' ? 7 : (period == 'month' ? 30 : 365);
      final startDate = DateTime.now().subtract(Duration(days: daysAgo));

      final snapshot = await firestore
          .collection('shippingRequests')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('createdAt')
          .get();

      // Group by date
      final Map<String, double> revenueByDate = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        final revenue = ((data['estimatedCost'] ?? 0.0) as num).toDouble();

        revenueByDate[dateKey] = (revenueByDate[dateKey] ?? 0.0) + revenue;
      }

      return revenueByDate.entries
          .map((e) => {'date': e.key, 'revenue': e.value})
          .toList();
    });

/// Best sellers provider - returns top shipping request types
final bestSellersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('shippingRequests').get();

      // Count by type
      final Map<String, int> countByType = {};
      final Map<String, double> revenueByType = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] ?? 'unknown';
        final revenue = ((data['estimatedCost'] ?? 0.0) as num).toDouble();

        countByType[type] = (countByType[type] ?? 0) + 1;
        revenueByType[type] = (revenueByType[type] ?? 0.0) + revenue;
      }

      return countByType.entries
          .map(
            (e) => {
              'type': e.key,
              'count': e.value,
              'revenue': revenueByType[e.key] ?? 0.0,
            },
          )
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    });

/// Vendor performance provider - returns affiliate performance
final vendorPerformanceProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('affiliates')
          .orderBy('totalEarnings', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'earnings': (data['totalEarnings'] ?? 0.0) as num,
          'shipments': (data['totalShipments'] ?? 0) as int,
          'status': data['status'] ?? 'pending',
        };
      }).toList();
    });

/// Shipping volume provider - returns shipping request counts by period
final shippingVolumeProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('shippingRequests').get();

      // Group by month for the last 12 months
      final Map<String, int> volumeByMonth = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final monthKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';

        volumeByMonth[monthKey] = (volumeByMonth[monthKey] ?? 0) + 1;
      }

      return volumeByMonth.entries
          .map((e) => {'month': e.key, 'volume': e.value})
          .toList()
        ..sort(
          (a, b) => (a['month'] as String).compareTo(b['month'] as String),
        );
    });

final revenueProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, period) async {
      // Aggregate revenue from Firestore shippingRequests
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      final snapshot = await firestore
          .collection('shippingRequests')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('status', whereIn: ['Delivered', 'In Transit'])
          .get();

      double totalRevenue = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['amount'] as num?)?.toDouble() ?? 0.0;
        count++;
      }

      return {
        'total': totalRevenue,
        'count': count,
        'average': count > 0 ? totalRevenue / count : 0.0,
        'period': period,
      };
    });
