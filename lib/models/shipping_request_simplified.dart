import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified Shipping Request Model - Aligned with Form Spec
/// Collection: 'shippingRequests'
///
/// This model captures ONLY the essential fields required by the shipping form:
/// - Freight Type (air or sea) – the more specific airport/door options are
///   handled later by agents when they contact the client.
/// - Shipment Details (description, HS code, route, dates, weight, dimensions, packaging)
/// - Sender Details (name, address, phone, email)
/// - Receiver Details (name, address, phone, email)
/// - Attachments (files)
/// - Other Information (additional notes)

class ShippingRequestSimplified {
  final String id;
  final String requesterId;
  final String? affiliateId;
  final String category; // guest, customer, or affiliate
  final String
      status; // 'pending', 'approved', 'in_transit', 'delivered', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 1. FREIGHT TYPE
  final String
      freightType; // 'air' or 'sea' (legacy: 'airport_to_airport'/'door_to_door')

  // 2. SHIPMENT DETAILS
  final String itemDescription; // *required
  final String departingLocation; // *required (Origin address)
  final String priority; // 'regular' or 'express'
  final String destinationLocation; // *required (Destination address)
  final double shipmentWeight; // in kg *required
  final double shipmentLength; // in cm *required
  final double shipmentWidth; // in cm *required
  final double shipmentHeight; // in cm *required
  final String shipmentPackaging; // Brief description *required

  // 3. SENDER DETAILS
  final String senderName; // *required
  final String senderAddress; // *required
  final String senderPhone; // *required
  final String senderEmail; // *required

  // 4. RECEIVER DETAILS
  final String receiverName; // *required
  final String receiverAddress; // *required
  final String receiverPhone; // *required
  final String receiverEmail; // *required

  // 5. ATTACHMENTS (Files)
  final List<ShippingDocument> attachments; // List of attached documents

  // 6. OTHER INFORMATION
  final String? otherInformation; // Additional notes/special requirements

  // System fields
  final String? trackingNumber;
  final String? assignedAdminId;
  final String? rejectionReason;
  final double estimatedCost;
  final double actualCost;

  ShippingRequestSimplified({
    required this.id,
    required this.requesterId,
    this.affiliateId,
    required this.category,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    required this.freightType,
    required this.itemDescription,
    required this.departingLocation,
    required this.priority,
    required this.destinationLocation,
    required this.shipmentWeight,
    required this.shipmentLength,
    required this.shipmentWidth,
    required this.shipmentHeight,
    required this.shipmentPackaging,
    required this.senderName,
    required this.senderAddress,
    required this.senderPhone,
    required this.senderEmail,
    required this.receiverName,
    required this.receiverAddress,
    required this.receiverPhone,
    required this.receiverEmail,
    this.attachments = const [],
    this.otherInformation,
    this.trackingNumber,
    this.assignedAdminId,
    this.rejectionReason,
    this.estimatedCost = 0.0,
    this.actualCost = 0.0,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    // Freight type is now stored directly as 'air' or 'sea'.
    // If older legacy values slip in, convert them for safety.
    String typeForRules;
    if (freightType == 'airport_to_airport' || freightType == 'air') {
      typeForRules = 'air';
    } else if (freightType == 'door_to_door' || freightType == 'sea') {
      typeForRules = 'sea';
    } else {
      typeForRules = 'sea'; // fallback
    }

    return {
      'requesterId': requesterId,
      'affiliateId': affiliateId,
      'status': 'pending', // NEW REQUESTS ALWAYS START AS PENDING
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'trackingNumber': trackingNumber,
      'category': category,

      // NEW SCHEMA FIELD NAMES (aligned with security rules)
      'type':
          typeForRules, // Maps 'door_to_door'->'sea', 'airport_to_airport'->'air'
      'description': itemDescription,
      'origin': departingLocation,
      'priority': priority,
      'destination': destinationLocation,
      'weight': shipmentWeight,
      'length': shipmentLength,
      'width': shipmentWidth,
      'height': shipmentHeight,
      'packaging': shipmentPackaging,

      // CLIENT INFO (not sender/receiver)
      'clientName': senderName,
      'clientEmail': senderEmail,
      'clientPhone': senderPhone,

      // ADDITIONAL FIELDS (kept for backward compatibility)
      'senderName': senderName,
      'senderAddress': senderAddress,
      'senderPhone': senderPhone,
      'senderEmail': senderEmail,
      'receiverName': receiverName,
      'receiverAddress': receiverAddress,
      'receiverPhone': receiverPhone,
      'receiverEmail': receiverEmail,

      // OTHER FIELDS
      'attachments': attachments.map((doc) => doc.toMap()).toList(),
      'otherInformation': otherInformation,
      'assignedAdminId': assignedAdminId,
      'rejectionReason': rejectionReason,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
    };
  }

  // Create from Firestore document
  factory ShippingRequestSimplified.fromFirestore(
    DocumentSnapshot<Object?> doc,
  ) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShippingRequestSimplified(
      id: doc.id,
      requesterId: (data['requesterId'] as String?) ?? '',
      affiliateId: data['affiliateId'] as String?,
      status: (data['status'] as String?) ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      freightType: () {
        final raw = (data['freightType'] as String?) ?? 'sea';
        if (raw == 'airport_to_airport' || raw == 'air') return 'air';
        if (raw == 'door_to_door' || raw == 'sea') return 'sea';
        return 'sea';
      }(),
      itemDescription: (data['itemDescription'] as String?) ?? '',
      departingLocation: (data['departingLocation'] as String?) ?? '',
      destinationLocation: (data['destinationLocation'] as String?) ?? '',
      shipmentWeight: (data['shipmentWeight'] as num?)?.toDouble() ?? 0.0,
      shipmentLength: (data['shipmentLength'] as num?)?.toDouble() ?? 0.0,
      shipmentWidth: (data['shipmentWidth'] as num?)?.toDouble() ?? 0.0,
      shipmentHeight: (data['shipmentHeight'] as num?)?.toDouble() ?? 0.0,
      shipmentPackaging: (data['shipmentPackaging'] as String?) ?? '',
      priority: () {
        final raw = (data['priority'] as String?) ?? 'regular';
        return raw == 'standard' ? 'regular' : raw;
      }(),
      senderName: (data['senderName'] as String?) ?? '',
      senderAddress: (data['senderAddress'] as String?) ?? '',
      senderPhone: (data['senderPhone'] as String?) ?? '',
      senderEmail: (data['senderEmail'] as String?) ?? '',
      receiverName: (data['receiverName'] as String?) ?? '',
      receiverAddress: (data['receiverAddress'] as String?) ?? '',
      receiverPhone: (data['receiverPhone'] as String?) ?? '',
      receiverEmail: (data['receiverEmail'] as String?) ?? '',
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((doc) =>
                  ShippingDocument.fromMap(doc as Map<String, dynamic>))
              .toList() ??
          [],
      otherInformation: data['otherInformation'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      assignedAdminId: data['assignedAdminId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      actualCost: (data['actualCost'] as num?)?.toDouble() ?? 0.0,
      category: (data['category'] as String?) ?? 'guest',
    );
  }
}

/// Document attachment model
class ShippingDocument {
  final String id;
  final String fileName;
  final String fileUrl; // Cloud Storage URL
  final String fileType; // 'invoice', 'proforma', 'packing_list', 'other'
  final int fileSizeBytes;
  final DateTime uploadedAt;

  ShippingDocument({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType = 'other',
    required this.fileSizeBytes,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory ShippingDocument.fromMap(Map<String, dynamic> map) {
    return ShippingDocument(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      fileUrl: map['fileUrl'] as String,
      fileType: map['fileType'] as String? ?? 'other',
      fileSizeBytes: map['fileSizeBytes'] as int,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }
}
