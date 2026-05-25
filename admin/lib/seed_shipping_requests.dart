import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('shippingRequests');

  print('🚢 Starting to seed shipping requests...\n');

  final requests = [
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
      'description':
          'Electronics and computer equipment - requires careful handling',
      'estimatedCost': 2800.00,
      'customsInfo': {
        'declared_value': 15000.00,
        'category': 'electronics',
        'requires_inspection': true,
      },
      'insuranceDetails': {
        'insured': true,
        'coverage_amount': 15000.00,
        'provider': 'Global Shipping Insurance',
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 5)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 2)),
      ),
    },
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
      'description': 'Commercial goods - textiles and garments (2 containers)',
      'estimatedCost': 8500.00,
      'customsInfo': {
        'declared_value': 45000.00,
        'category': 'textiles',
        'hs_code': '6204.63',
        'containers': 2,
      },
      'insuranceDetails': {
        'insured': true,
        'coverage_amount': 50000.00,
        'provider': 'Marine Cargo Insurance Ltd',
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 12)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 1)),
      ),
    },
    {
      'requesterId': 'user_004',
      'clientName': 'Emma Johnson',
      'clientEmail': 'emma.j@example.com',
      'clientPhone': '+1-555-0234',
      'type': 'air',
      'status': 'carrier_assigned',
      'priority': 'urgent',
      'origin': 'New York, USA',
      'destination': 'Abuja, Nigeria',
      'weight': 89.0,
      'length': 60.0,
      'width': 40.0,
      'height': 35.0,
      'description': 'Medical supplies - temperature sensitive',
      'estimatedCost': 3200.00,
      'carrierName': 'DHL Express',
      'trackingNumber': 'DHL1234567890',
      'estimatedDelivery': Timestamp.fromDate(
        DateTime.now().add(Duration(days: 3)),
      ),
      'customsInfo': {
        'declared_value': 8500.00,
        'category': 'medical',
        'requires_cold_storage': true,
      },
      'insuranceDetails': {
        'insured': true,
        'coverage_amount': 10000.00,
        'provider': 'Medical Cargo Insurance',
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 8)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(hours: 6)),
      ),
    },
    {
      'requesterId': 'user_005',
      'affiliateId': 'AFF-003',
      'clientName': 'David Okonkwo',
      'clientEmail': 'david.okonkwo@example.com',
      'clientPhone': '+234-803-456-7890',
      'type': 'air',
      'status': 'in_transit',
      'priority': 'express',
      'origin': 'Dubai, UAE',
      'destination': 'Kano, Nigeria',
      'weight': 215.0,
      'length': 100.0,
      'width': 80.0,
      'height': 70.0,
      'description': 'Auto parts and accessories',
      'estimatedCost': 4100.00,
      'carrierName': 'Emirates SkyCargo',
      'trackingNumber': 'EK9876543210',
      'estimatedDelivery': Timestamp.fromDate(
        DateTime.now().add(Duration(days: 1)),
      ),
      'currentLocation': 'In transit - Nnamdi Azikiwe International Airport',
      'customsInfo': {
        'declared_value': 22000.00,
        'category': 'automotive',
        'hs_code': '8708.99',
      },
      'insuranceDetails': {'insured': true, 'coverage_amount': 25000.00},
      'performanceMetrics': {
        'on_time_percentage': 95,
        'customs_clearance_hours': 4,
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 6)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(hours: 3)),
      ),
    },
    {
      'requesterId': 'user_006',
      'clientName': 'Lisa Anderson',
      'clientEmail': 'lisa.anderson@example.com',
      'clientPhone': '+44-20-7946-0958',
      'type': 'sea',
      'status': 'in_transit',
      'priority': 'standard',
      'origin': 'Rotterdam, Netherlands',
      'destination': 'Apapa Port, Nigeria',
      'weight': 12800.0,
      'length': 300.0,
      'width': 150.0,
      'height': 120.0,
      'description': 'Industrial machinery and equipment (3 containers)',
      'estimatedCost': 15000.00,
      'carrierName': 'Maersk Line',
      'trackingNumber': 'MAEU567891234',
      'estimatedDelivery': Timestamp.fromDate(
        DateTime.now().add(Duration(days: 8)),
      ),
      'currentLocation': 'At sea - Mediterranean route',
      'customsInfo': {
        'declared_value': 185000.00,
        'category': 'machinery',
        'hs_code': '8479.89',
        'containers': 3,
      },
      'insuranceDetails': {
        'insured': true,
        'coverage_amount': 200000.00,
        'provider': 'Lloyd\'s Marine Insurance',
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 25)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 1)),
      ),
    },
    {
      'requesterId': 'user_007',
      'affiliateId': 'AFF-001',
      'clientName': 'Ahmed Hassan',
      'clientEmail': 'ahmed.hassan@example.com',
      'clientPhone': '+971-50-123-4567',
      'type': 'air',
      'status': 'delivered',
      'priority': 'express',
      'origin': 'Istanbul, Turkey',
      'destination': 'Lagos, Nigeria',
      'weight': 156.0,
      'length': 90.0,
      'width': 70.0,
      'height': 60.0,
      'description': 'Fashion items and accessories',
      'estimatedCost': 3400.00,
      'carrierName': 'Turkish Cargo',
      'trackingNumber': 'TK1122334455',
      'estimatedDelivery': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 2)),
      ),
      'deliveredAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 2)),
      ),
      'currentLocation': 'Delivered to warehouse - Lagos',
      'customsInfo': {
        'declared_value': 18500.00,
        'category': 'fashion',
        'customs_cleared': true,
      },
      'insuranceDetails': {'insured': true, 'coverage_amount': 20000.00},
      'performanceMetrics': {
        'delivery_rating': 5,
        'on_time': true,
        'total_days': 4,
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 15)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 2)),
      ),
    },
    {
      'requesterId': 'user_008',
      'clientName': 'Grace Adebayo',
      'clientEmail': 'grace.adebayo@example.com',
      'clientPhone': '+234-901-234-5678',
      'type': 'sea',
      'status': 'delivered',
      'priority': 'standard',
      'origin': 'Mumbai, India',
      'destination': 'Tin Can Island Port, Nigeria',
      'weight': 8900.0,
      'length': 280.0,
      'width': 140.0,
      'height': 110.0,
      'description': 'Food products - rice and grains (bulk)',
      'estimatedCost': 12000.00,
      'carrierName': 'MSC Mediterranean Shipping',
      'trackingNumber': 'MSC789456123',
      'estimatedDelivery': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 5)),
      ),
      'deliveredAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 5)),
      ),
      'currentLocation': 'Delivered to warehouse - Lagos',
      'customsInfo': {
        'declared_value': 65000.00,
        'category': 'food',
        'hs_code': '1006.30',
        'containers': 2,
        'customs_cleared': true,
      },
      'insuranceDetails': {'insured': true, 'coverage_amount': 70000.00},
      'performanceMetrics': {
        'delivery_rating': 4,
        'on_time': true,
        'total_days': 32,
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 42)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 5)),
      ),
    },
    {
      'requesterId': 'user_009',
      'affiliateId': 'AFF-002',
      'clientName': 'Robert Martinez',
      'clientEmail': 'robert.martinez@example.com',
      'clientPhone': '+1-555-0789',
      'type': 'air',
      'status': 'cancelled',
      'priority': 'standard',
      'origin': 'Los Angeles, USA',
      'destination': 'Port Harcourt, Nigeria',
      'weight': 178.0,
      'length': 85.0,
      'width': 65.0,
      'height': 55.0,
      'description': 'Furniture and home decor items',
      'estimatedCost': 3800.00,
      'cancellationReason':
          'Client requested cancellation - changed delivery plans',
      'cancelledAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 3)),
      ),
      'customsInfo': {'declared_value': 12000.00, 'category': 'furniture'},
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 10)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: 3)),
      ),
    },
    {
      'requesterId': 'user_010',
      'clientName': 'Fatima Yusuf',
      'clientEmail': 'fatima.yusuf@example.com',
      'clientPhone': '+234-805-987-6543',
      'type': 'sea',
      'status': 'pending',
      'priority': 'standard',
      'origin': 'Hamburg, Germany',
      'destination': 'Calabar Port, Nigeria',
      'weight': 6750.0,
      'length': 260.0,
      'width': 130.0,
      'height': 105.0,
      'description': 'Building materials - tiles and fixtures (2 containers)',
      'estimatedCost': 9800.00,
      'customsInfo': {
        'declared_value': 52000.00,
        'category': 'construction',
        'hs_code': '6907.21',
        'containers': 2,
      },
      'insuranceDetails': {
        'insured': true,
        'coverage_amount': 55000.00,
        'provider': 'German Marine Insurance',
      },
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(hours: 18)),
      ),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(hours: 18)),
      ),
    },
  ];

  int count = 0;
  for (final request in requests) {
    final docRef = collection.doc();
    final requestData = {'id': docRef.id, ...request};

    await docRef.set(requestData);
    count++;
    print(
      '✅ Added: ${request['clientName']} - ${request['status']} (${request['type']})',
    );
  }

  print('\n🎉 Successfully seeded $count shipping requests!');
  print('\nStatus breakdown:');
  print('  - Pending: 1 (existing) + 1 (new) = 2');
  print('  - Reviewing: 1');
  print('  - Approved: 1');
  print('  - Carrier Assigned: 1');
  print('  - In Transit: 2');
  print('  - Delivered: 2');
  print('  - Cancelled: 1');
  print('\nType breakdown:');
  print('  - Air: 6');
  print('  - Sea: 5');
  print('\nTotal: 10 shipping requests (1 existing + 9 new)\n');
}
