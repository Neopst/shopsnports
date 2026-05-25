// FILE: admin/admin/lib/features/shipping/domain/shipping_request_simplified_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ShippingFreightType { air, sea, airportToAirport, doorToDoor }

enum ShippingRequestStatus {
  pending,
  approved,
  inTransit,
  delivered,
  cancelled,
}

class ShippingRequestSimplified {
  final String id;
  final String requesterId;
  final String? affiliateId;
  final String category; // guest, customer, affiliate
  final ShippingRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 1. FREIGHT TYPE
  final ShippingFreightType freightType;

  // 2. SHIPMENT DETAILS
  final String itemDescription;
  final String departingLocation;
  final String priority; // regular or express
  final String destinationLocation;
  final double shipmentWeight; // in kg
  final double shipmentLength; // in cm
  final double shipmentWidth; // in cm
  final double shipmentHeight; // in cm
  final String shipmentPackaging;

  // 3. SENDER DETAILS
  final String senderName;
  final String senderAddress;
  final String senderPhone;
  final String senderEmail;

  // 4. RECEIVER DETAILS
  final String receiverName;
  final String receiverAddress;
  final String receiverPhone;
  final String receiverEmail;

  // 5. ATTACHMENTS
  final List<ShippingDocumentModel> attachments;

  // 6. OTHER INFORMATION
  final String? otherInformation;

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
    this.status = ShippingRequestStatus.pending,
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

  // Display status
  String get statusDisplay {
    switch (status) {
      case ShippingRequestStatus.pending:
        return 'Pending';
      case ShippingRequestStatus.approved:
        return 'Approved';
      case ShippingRequestStatus.inTransit:
        return 'In Transit';
      case ShippingRequestStatus.delivered:
        return 'Delivered';
      case ShippingRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Display freight type
  String get freightTypeDisplay {
    switch (freightType) {
      case ShippingFreightType.air:
        return 'Air';
      case ShippingFreightType.sea:
        return 'Sea';
      case ShippingFreightType.airportToAirport:
        return 'Airport to Airport';
      case ShippingFreightType.doorToDoor:
        return 'Door to Door';
    }
  }

  // Factory constructor from Firestore
  // Supports both OLD field names (freightType, departingLocation, etc.)
  // AND NEW field names (type, origin, destination, etc.)
  factory ShippingRequestSimplified.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    // Support both old and new field names
    final freightTypeValue =
        (data['type'] as String?) ?? (data['freightType'] as String?) ?? 'sea';
    final itemDescValue =
        (data['itemDescription'] as String?) ??
        (data['description'] as String?) ??
        '';
    final depLocValue =
        (data['departingLocation'] as String?) ??
        (data['origin'] as String?) ??
        '';
    final destLocValue =
        (data['destinationLocation'] as String?) ??
        (data['destination'] as String?) ??
        '';
    final weightValue =
        (data['shipmentWeight'] as num?) ?? (data['weight'] as num?) ?? 0.0;
    final lengthValue =
        (data['shipmentLength'] as num?) ?? (data['length'] as num?) ?? 0.0;
    final widthValue =
        (data['shipmentWidth'] as num?) ?? (data['width'] as num?) ?? 0.0;
    final heightValue =
        (data['shipmentHeight'] as num?) ?? (data['height'] as num?) ?? 0.0;
    final packagingValue =
        (data['shipmentPackaging'] as String?) ??
        (data['packaging'] as String?) ??
        '';
    final clientNameValue =
        (data['senderName'] as String?) ??
        (data['clientName'] as String?) ??
        '';
    final clientEmailValue =
        (data['senderEmail'] as String?) ??
        (data['clientEmail'] as String?) ??
        '';
    final clientPhoneValue =
        (data['senderPhone'] as String?) ??
        (data['clientPhone'] as String?) ??
        '';

    return ShippingRequestSimplified(
      id: docId,
      requesterId: (data['requesterId'] as String?) ?? '',
      affiliateId: data['affiliateId'] as String?,
      category: (data['category'] as String?) ?? 'guest',
      status: _parseStatus(data['status'] as String? ?? 'pending'),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? _parseTimestamp(data['updatedAt'])
          : null,
      freightType: _parseFreightType(freightTypeValue),
      itemDescription: itemDescValue,
      departingLocation: depLocValue,
      priority: () {
        final raw = (data['priority'] as String?) ?? 'regular';
        return raw == 'standard' ? 'regular' : raw;
      }(),
      destinationLocation: destLocValue,
      shipmentWeight: weightValue.toDouble(),
      shipmentLength: lengthValue.toDouble(),
      shipmentWidth: widthValue.toDouble(),
      shipmentHeight: heightValue.toDouble(),
      shipmentPackaging: packagingValue,
      senderName: clientNameValue,
      senderAddress: (data['senderAddress'] as String?) ?? '',
      senderPhone: clientPhoneValue,
      senderEmail: clientEmailValue,
      receiverName: (data['receiverName'] as String?) ?? '',
      receiverAddress: (data['receiverAddress'] as String?) ?? '',
      receiverPhone: (data['receiverPhone'] as String?) ?? '',
      receiverEmail: (data['receiverEmail'] as String?) ?? '',
      attachments:
          (data['attachments'] as List<dynamic>?)
              ?.map(
                (doc) =>
                    ShippingDocumentModel.fromMap(doc as Map<String, dynamic>),
              )
              .toList() ??
          [],
      otherInformation: data['otherInformation'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      assignedAdminId: data['assignedAdminId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      actualCost: (data['actualCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static ShippingRequestStatus _parseStatus(String status) {
    switch (status) {
      case 'approved':
        return ShippingRequestStatus.approved;
      case 'in_transit':
        return ShippingRequestStatus.inTransit;
      case 'delivered':
        return ShippingRequestStatus.delivered;
      case 'cancelled':
        return ShippingRequestStatus.cancelled;
      default:
        return ShippingRequestStatus.pending;
    }
  }

  static ShippingFreightType _parseFreightType(String type) {
    switch (type) {
      case 'door_to_door':
        return ShippingFreightType.doorToDoor;
      default:
        return ShippingFreightType.airportToAirport;
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }
}

class ShippingDocumentModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType; // 'invoice', 'proforma', 'packing_list', 'other'
  final int fileSizeBytes;
  final DateTime uploadedAt;

  ShippingDocumentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType = 'other',
    required this.fileSizeBytes,
    required this.uploadedAt,
  });

  String get fileSizeMB => (fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);

  factory ShippingDocumentModel.fromMap(Map<String, dynamic> map) {
    return ShippingDocumentModel(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      fileUrl: map['fileUrl'] as String,
      fileType: map['fileType'] as String? ?? 'other',
      fileSizeBytes: map['fileSizeBytes'] as int,
      uploadedAt: map['uploadedAt'] is Timestamp
          ? (map['uploadedAt'] as Timestamp).toDate()
          : (map['uploadedAt'] as DateTime),
    );
  }
}
