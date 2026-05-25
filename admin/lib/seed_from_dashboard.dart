// Run this from the debug console while the dashboard is running:
// In VS Code, open Debug Console and paste:
//
// (Not a standalone file - for manual console execution)

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedShippingFromDashboard() async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('shippingRequests');

  print('🚢 Starting to seed 9 shipping requests...\n');

  final requests = [
    // 1. Reviewing
    {
      'requesterId': 'user_002',
      'affiliateId': 'AFF-001',
      'clientName': 'Sarah Williams',
      'clientEmail': 'sarah.williams@example.com',
      'clientPhone': '+1-555-0102',
      'type': 'air',
      'status': 'reviewing',
      'priority': 'express',
      'origin': 'London, UK',
      'destination': 'Lagos, Nigeria',
      'weight': 125.5,
      'length': 80.0,
      'width': 60.0,
      'height': 50.0,
      'description': 'Electronics',
      'estimatedCost': 2800.00,
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 5)),
      ),
    },
    // 2. Approved (sea)
    {
      'requesterId': 'user_003',
      'affiliateId': 'AFF-002',
      'clientName': 'Michael Chen',
      'clientEmail': 'michael.chen@example.com',
      'clientPhone': '+86-138-0000-1234',
      'type': 'sea',
      'status': 'approved',
      'priority': 'standard',
      'origin': 'Shanghai, China',
      'destination': 'Port Harcourt, Nigeria',
      'weight': 5420.0,
      'length': 240.0,
      'width': 120.0,
      'height': 100.0,
      'description': 'Textiles (2 containers)',
      'estimatedCost': 8500.00,
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 12)),
      ),
    },
    // 3. Approved (sea)
    {
      'requesterId': 'user_004',
      'affiliateId': 'AFF-003',
      'clientName': 'Emma Rodriguez',
      'clientEmail': 'emma.rodriguez@example.com',
      'clientPhone': '+34-612-345-678',
      'type': 'sea',
      'status': 'approved',
      'priority': 'economy',
      'origin': 'Barcelona, Spain',
      'destination': 'Lagos, Nigeria',
      'weight': 3200.0,
      'length': 200.0,
      'width': 100.0,
      'height': 80.0,
      'description': 'Furniture',
      'estimatedCost': 5200.00,
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 10)),
      ),
    },
    // 4. In Transit (air)
    {
      'requesterId': 'user_005',
      'affiliateId': 'AFF-001',
      'clientName': 'Ahmed Hassan',
      'clientEmail': 'ahmed.hassan@example.com',
      'clientPhone': '+971-50-123-4567',
      'type': 'air',
      'status': 'in_transit',
      'priority': 'express',
      'origin': 'Dubai, UAE',
      'destination': 'Abuja, Nigeria',
      'weight': 89.5,
      'length': 60.0,
      'width': 40.0,
      'height': 35.0,
      'description': 'Medical supplies',
      'estimatedCost': 3500.00,
      'trackingNumber': 'TRK-AIR-20260120-001',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 8)),
      ),
    },
    // 5. In Transit (sea)
    {
      'requesterId': 'user_006',
      'affiliateId': 'AFF-002',
      'clientName': 'Li Wei',
      'clientEmail': 'li.wei@example.com',
      'clientPhone': '+86-139-1234-5678',
      'type': 'sea',
      'status': 'in_transit',
      'priority': 'standard',
      'origin': 'Guangzhou, China',
      'destination': 'Lagos, Nigeria',
      'weight': 8900.0,
      'length': 300.0,
      'width': 150.0,
      'height': 120.0,
      'description': 'Machinery (3 containers)',
      'estimatedCost': 12500.00,
      'trackingNumber': 'TRK-SEA-20260105-001',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 25)),
      ),
    },
    // 6. In Transit (air)
    {
      'requesterId': 'user_007',
      'affiliateId': 'AFF-003',
      'clientName': 'Fatima Okonkwo',
      'clientEmail': 'fatima.okonkwo@example.com',
      'clientPhone': '+234-803-123-4567',
      'type': 'air',
      'status': 'in_transit',
      'priority': 'standard',
      'origin': 'New York, USA',
      'destination': 'Lagos, Nigeria',
      'weight': 156.0,
      'length': 90.0,
      'width': 65.0,
      'height': 50.0,
      'description': 'Personal effects',
      'estimatedCost': 4200.00,
      'trackingNumber': 'TRK-AIR-20260118-002',
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 6)),
      ),
    },
    // 7. Delivered
    {
      'requesterId': 'user_008',
      'affiliateId': 'AFF-001',
      'clientName': 'Hans Mueller',
      'clientEmail': 'hans.mueller@example.com',
      'clientPhone': '+49-151-1234-5678',
      'type': 'air',
      'status': 'delivered',
      'priority': 'express',
      'origin': 'Frankfurt, Germany',
      'destination': 'Abuja, Nigeria',
      'weight': 67.5,
      'length': 55.0,
      'width': 45.0,
      'height': 40.0,
      'description': 'Documents',
      'estimatedCost': 1800.00,
      'trackingNumber': 'TRK-AIR-20260110-003',
      'deliveredAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2)),
      ),
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 15)),
      ),
    },
    // 8. Delivered
    {
      'requesterId': 'user_009',
      'affiliateId': 'AFF-002',
      'clientName': 'Yuki Tanaka',
      'clientEmail': 'yuki.tanaka@example.com',
      'clientPhone': '+81-90-1234-5678',
      'type': 'sea',
      'status': 'delivered',
      'priority': 'economy',
      'origin': 'Tokyo, Japan',
      'destination': 'Port Harcourt, Nigeria',
      'weight': 4500.0,
      'length': 220.0,
      'width': 110.0,
      'height': 95.0,
      'description': 'Auto parts',
      'estimatedCost': 7800.00,
      'trackingNumber': 'TRK-SEA-20251220-002',
      'deliveredAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 5)),
      ),
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 35)),
      ),
    },
    // 9. Cancelled
    {
      'requesterId': 'user_010',
      'affiliateId': 'AFF-003',
      'clientName': 'Carlos Mendoza',
      'clientEmail': 'carlos.mendoza@example.com',
      'clientPhone': '+52-55-1234-5678',
      'type': 'air',
      'status': 'cancelled',
      'priority': 'standard',
      'origin': 'Mexico City, Mexico',
      'destination': 'Lagos, Nigeria',
      'weight': 95.0,
      'length': 70.0,
      'width': 50.0,
      'height': 45.0,
      'description': 'Cancelled - customs',
      'estimatedCost': 2400.00,
      'cancellationReason': 'Missing documentation',
      'cancelledAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 3)),
      ),
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)),
      ),
    },
  ];

  int count = 0;
  for (final request in requests) {
    await collection.add(request);
    count++;
    print('✅ $count/9: ${request['clientName']} - ${request['status']}');
  }

  print(
    '\n✅ Done! Created 9 requests. Total in DB: ${(await collection.get()).docs.length}',
  );
}
