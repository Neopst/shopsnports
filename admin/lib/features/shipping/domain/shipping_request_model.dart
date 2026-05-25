// FILE: lib/features/shipping/domain/shipping_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ShippingType { air, sea }

enum ShippingStatus { pending, approved, inTransit, delivered, cancelled }

enum ShippingPriority { standard, express, urgent }

class ShippingRequest {
  final String id;
  final String requesterId;
  final String? affiliateId;
  final String? clientName;
  final String? clientEmail;
  final String? clientPhone;
  final ShippingType type;
  final ShippingStatus status;
  final ShippingPriority priority;
  final String origin;
  final String destination;
  final double weight;
  final double length;
  final double width;
  final double height;
  final String description;
  final double estimatedCost;
  final double actualCost;
  final String? trackingNumber;
  final String? carrier;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final List<Map<String, dynamic>>
  documents; // Changed from List<String> to support full document objects
  final Map<String, dynamic> insuranceDetails;
  final Map<String, dynamic> customsInfo;
  final Map<String, dynamic> performanceMetrics;
  final String? assignedAdminId;
  final String? rejectionReason;
  final double affiliateCommission;
  final bool requiresInsurance;
  final bool requiresCustomsClearance;

  ShippingRequest({
    required this.id,
    required this.requesterId,
    this.affiliateId,
    this.clientName,
    this.clientEmail,
    this.clientPhone,
    required this.type,
    required this.status,
    this.priority = ShippingPriority.standard,
    required this.origin,
    required this.destination,
    required this.weight,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    required this.description,
    required this.estimatedCost,
    this.actualCost = 0,
    this.trackingNumber,
    this.carrier,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDelivery,
    this.actualDelivery,
    this.documents = const [],
    this.insuranceDetails = const {},
    this.customsInfo = const {},
    this.performanceMetrics = const {},
    this.assignedAdminId,
    this.rejectionReason,
    this.affiliateCommission = 0,
    this.requiresInsurance = false,
    this.requiresCustomsClearance = false,
  });

  double get volume => length * width * height;
  bool get isInternational =>
      !origin.contains('Nigeria') || !destination.contains('Nigeria');
  int get daysInTransit => actualDelivery != null
      ? actualDelivery!.difference(createdAt).inDays
      : DateTime.now().difference(createdAt).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'affiliateId': affiliateId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'origin': origin,
      'destination': destination,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'description': description,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'actualDelivery': actualDelivery != null
          ? Timestamp.fromDate(actualDelivery!)
          : null,
      'documents': documents,
      'insuranceDetails': insuranceDetails,
      'customsInfo': customsInfo,
      'performanceMetrics': performanceMetrics,
      'assignedAdminId': assignedAdminId,
      'rejectionReason': rejectionReason,
      'affiliateCommission': affiliateCommission,
      'requiresInsurance': requiresInsurance,
      'requiresCustomsClearance': requiresCustomsClearance,
    };
  }

  factory ShippingRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShippingRequest(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      affiliateId: data['affiliateId'],
      clientName: data['clientName'],
      clientEmail: data['clientEmail'],
      clientPhone: data['clientPhone'],
      type: ShippingType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ShippingType.air,
      ),
      status: ShippingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ShippingStatus.pending,
      ),
      priority: ShippingPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => ShippingPriority.standard,
      ),
      origin: data['origin'] ?? '',
      destination: data['destination'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      length: (data['length'] ?? 0).toDouble(),
      width: (data['width'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      estimatedCost: (data['estimatedCost'] ?? 0).toDouble(),
      actualCost: (data['actualCost'] ?? 0).toDouble(),
      trackingNumber: data['trackingNumber'],
      carrier: data['carrier'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      estimatedDelivery: data['estimatedDelivery'] != null
          ? (data['estimatedDelivery'] as Timestamp).toDate()
          : null,
      actualDelivery: data['actualDelivery'] != null
          ? (data['actualDelivery'] as Timestamp).toDate()
          : null,
      documents:
          (data['documents'] as List<dynamic>?)
              ?.map((doc) => Map<String, dynamic>.from(doc as Map))
              .toList() ??
          [],
      insuranceDetails: Map<String, dynamic>.from(
        data['insuranceDetails'] ?? {},
      ),
      customsInfo: Map<String, dynamic>.from(data['customsInfo'] ?? {}),
      performanceMetrics: Map<String, dynamic>.from(
        data['performanceMetrics'] ?? {},
      ),
      assignedAdminId: data['assignedAdminId'],
      rejectionReason: data['rejectionReason'],
      affiliateCommission: (data['affiliateCommission'] ?? 0).toDouble(),
      requiresInsurance: data['requiresInsurance'] ?? false,
      requiresCustomsClearance: data['requiresCustomsClearance'] ?? false,
    );
  }
}
