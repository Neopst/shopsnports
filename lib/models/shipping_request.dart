import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Shipping Request Model - Synced with Admin Dashboard
/// Reference: lib/admin_flutter/reference/admin_dashboard/lib/features/shipping/domain/shipping_request_model.dart
///
/// ECS API Integration:
/// - POST /api/v1/shipping/requests - Create shipping request
/// - GET /api/v1/shipping/requests/:id - Get request details
/// - GET /api/v1/shipping/requests - List user requests
/// - PATCH /api/v1/shipping/requests/:id - Update request
///
/// Firestore Collection: 'shipping_requests'
/// Document ID: Auto-generated request ID

class ShippingRequest {
  final String id;
  final String requesterId;
  final String? affiliateId;

  // Client Information
  final String? clientName;
  final String? clientEmail;
  final String? clientPhone;

  // Basic Shipping Information
  final ShippingType type;
  final ShippingStatus status;
  final ShippingPriority priority;
  final String origin;
  final String destination;

  // Shipper Information
  final String? shipperType; // 'individual' or 'company'
  final String? shipperCompanyName;
  final String? shipperFullName;
  final String? shipperEmail;
  final String? shipperPhone;
  final String? shipperAddressLine1;
  final String? shipperAddressLine2;
  final String? shipperCity;
  final String? shipperState;
  final String? shipperCountry;
  final String? shipperZipCode;
  final String? shipperTaxId;
  final String? shipperVatNumber;

  // Consignee Information
  final String? consigneeType; // 'individual' or 'company'
  final String? consigneeCompanyName;
  final String? consigneeFullName;
  final String? consigneeEmail;
  final String? consigneePhone;
  final String? consigneeAddressLine1;
  final String? consigneeAddressLine2;
  final String? consigneeCity;
  final String? consigneeState;
  final String? consigneeCountry;
  final String? consigneeZipCode;

  // Cargo Details
  final double weight;
  final double length;
  final double width;
  final double height;
  final String description;
  final String? hsCode; // Harmonized System Code
  final String? commodityType;
  final String? packageType; // 'pallets', 'boxes', 'crates', etc.
  final int? numberOfPackages;
  final String? unNumber; // UN Number for dangerous goods
  final bool isDangerousGoods;
  final bool isPerishable;
  final bool isFragile;
  final String? specialHandling;

  // Air Freight Specific
  final String? airportOfOrigin;
  final String? airportOfDestination;
  final String? preferredAirline;
  final String? airServiceLevel; // 'standard', 'express', 'charter'
  final String? uldType; // Unit Load Device
  final String? mawbNumber; // Master Air Waybill
  final String? hawbNumber; // House Air Waybill
  final DateTime? cargoReadyDate;
  final DateTime? expectedShippingDate;

  // Sea Freight Specific
  final String? portOfLoading;
  final String? portOfDischarge;
  final String? finalDestinationPort;
  final String? containerType; // 'FCL' or 'LCL'
  final String? containerSize; // '20ft', '40ft', '40ft HC', etc.
  final int? numberOfContainers;
  final String? containerOwnership; // 'SOC' or 'COC'
  final String? vesselName;
  final String? voyageNumber;
  final String?
      billOfLadingType; // 'Original', 'Seaway Bill', 'Express Release'
  final String? billOfLadingInstructions;
  final String? transshipmentPoints;
  final String? preCarriage;
  final String? onCarriage;
  final DateTime? lastReceivingDate;
  final DateTime? carrierCutoffDate;

  // Shipping Terms & Services
  final String? incoterms; // 'EXW', 'FOB', 'CIF', 'DDP', etc.
  final String? freightPaymentTerms; // 'prepaid' or 'collect'
  final String? insuranceType;
  final double? insuranceValue;
  final String? customsBroker;
  final bool needsCustomsClearance;

  // Commercial & Customs
  final String? invoiceNumber;
  final double? invoiceValue;
  final String? invoiceCurrency;
  final String? exportLicenseNumber;
  final String? importLicenseNumber;
  final String? certificateOfOrigin;

  // Special Instructions
  final String? specialInstructions;
  final String? deliveryInstructions;
  final String? pickupInstructions;

  // Existing Fields (maintained for backward compatibility)
  final double estimatedCost;
  final double actualCost;
  final String? trackingNumber;
  final String? carrier;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final List<String> documents;
  final Map<String, dynamic> insuranceDetails;
  final Map<String, dynamic> customsInfo;
  final Map<String, dynamic> performanceMetrics;
  final String? assignedAdminId;
  final String? rejectionReason;
  final double affiliateCommission;
  final bool requiresInsurance;
  final bool requiresCustomsClearance;

  // Submission metadata
  final String? submittedBy; // 'affiliate' or 'client'
  final String? shareToken; // For client-submitted forms
  
  // Form Share Tracking (NEW)
  final String? formShareToken;        // SHARE-AFF-2026-XXXXX token from form share link
  final String? formShareTokenEmail;   // Client email from form share
  final String submissionType;         // 'direct' | 'form_share' | 'admin' (how request was submitted)
  final String? affiliateToken;        // SHOP-AFF-2026-XXXXX (if affiliate tagged via token)
  final String? affiliateTokenId;      // Reference ID to affiliate_token document

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
    // Shipper Information
    this.shipperType,
    this.shipperCompanyName,
    this.shipperFullName,
    this.shipperEmail,
    this.shipperPhone,
    this.shipperAddressLine1,
    this.shipperAddressLine2,
    this.shipperCity,
    this.shipperState,
    this.shipperCountry,
    this.shipperZipCode,
    this.shipperTaxId,
    this.shipperVatNumber,
    // Consignee Information
    this.consigneeType,
    this.consigneeCompanyName,
    this.consigneeFullName,
    this.consigneeEmail,
    this.consigneePhone,
    this.consigneeAddressLine1,
    this.consigneeAddressLine2,
    this.consigneeCity,
    this.consigneeState,
    this.consigneeCountry,
    this.consigneeZipCode,
    // Cargo Details
    required this.weight,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    required this.description,
    this.hsCode,
    this.commodityType,
    this.packageType,
    this.numberOfPackages,
    this.unNumber,
    this.isDangerousGoods = false,
    this.isPerishable = false,
    this.isFragile = false,
    this.specialHandling,
    // Air Freight Specific
    this.airportOfOrigin,
    this.airportOfDestination,
    this.preferredAirline,
    this.airServiceLevel,
    this.uldType,
    this.mawbNumber,
    this.hawbNumber,
    this.cargoReadyDate,
    this.expectedShippingDate,
    // Sea Freight Specific
    this.portOfLoading,
    this.portOfDischarge,
    this.finalDestinationPort,
    this.containerType,
    this.containerSize,
    this.numberOfContainers,
    this.containerOwnership,
    this.vesselName,
    this.voyageNumber,
    this.billOfLadingType,
    this.billOfLadingInstructions,
    this.transshipmentPoints,
    this.preCarriage,
    this.onCarriage,
    this.lastReceivingDate,
    this.carrierCutoffDate,
    // Shipping Terms & Services
    this.incoterms,
    this.freightPaymentTerms,
    this.insuranceType,
    this.insuranceValue,
    this.customsBroker,
    this.needsCustomsClearance = false,
    // Commercial & Customs
    this.invoiceNumber,
    this.invoiceValue,
    this.invoiceCurrency,
    this.exportLicenseNumber,
    this.importLicenseNumber,
    this.certificateOfOrigin,
    // Special Instructions
    this.specialInstructions,
    this.deliveryInstructions,
    this.pickupInstructions,
    // Existing Fields
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
    // Submission metadata
    this.submittedBy,
    this.shareToken,
    // Form Share Tracking (NEW)
    this.formShareToken,
    this.formShareTokenEmail,
    this.submissionType = 'direct',
    this.affiliateToken,
    this.affiliateTokenId,
  });

  double get volume => length * width * height;
  bool get isInternational =>
      !origin.contains('Nigeria') || !destination.contains('Nigeria');
  int get daysInTransit => actualDelivery != null
      ? actualDelivery!.difference(createdAt).inDays
      : DateTime.now().difference(createdAt).inDays;

  /// Create ShippingRequest from Firestore document
  factory ShippingRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShippingRequest.fromMap(data, doc.id);
  }

  /// Create ShippingRequest from Map
  factory ShippingRequest.fromMap(Map<String, dynamic> map, [String? id]) {
    return ShippingRequest(
      id: id ?? map['id'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      affiliateId: map['affiliateId'] as String?,
      clientName: map['clientName'] as String?,
      clientEmail: map['clientEmail'] as String?,
      clientPhone: map['clientPhone'] as String?,
      type: map['type'] != null
          ? ShippingTypeExtension.fromJson(map['type'] as String)
          : ShippingType.air,
      status: map['status'] != null
          ? ShippingStatusExtension.fromJson(map['status'] as String)
          : ShippingStatus.pending,
      priority: map['priority'] != null
          ? ShippingPriorityExtension.fromJson(map['priority'] as String)
          : ShippingPriority.standard,
      origin: map['origin'] as String? ?? '',
      destination: map['destination'] as String? ?? '',
      // Shipper Information
      shipperType: map['shipperType'] as String?,
      shipperCompanyName: map['shipperCompanyName'] as String?,
      shipperFullName: map['shipperFullName'] as String?,
      shipperEmail: map['shipperEmail'] as String?,
      shipperPhone: map['shipperPhone'] as String?,
      shipperAddressLine1: map['shipperAddressLine1'] as String?,
      shipperAddressLine2: map['shipperAddressLine2'] as String?,
      shipperCity: map['shipperCity'] as String?,
      shipperState: map['shipperState'] as String?,
      shipperCountry: map['shipperCountry'] as String?,
      shipperZipCode: map['shipperZipCode'] as String?,
      shipperTaxId: map['shipperTaxId'] as String?,
      shipperVatNumber: map['shipperVatNumber'] as String?,
      // Consignee Information
      consigneeType: map['consigneeType'] as String?,
      consigneeCompanyName: map['consigneeCompanyName'] as String?,
      consigneeFullName: map['consigneeFullName'] as String?,
      consigneeEmail: map['consigneeEmail'] as String?,
      consigneePhone: map['consigneePhone'] as String?,
      consigneeAddressLine1: map['consigneeAddressLine1'] as String?,
      consigneeAddressLine2: map['consigneeAddressLine2'] as String?,
      consigneeCity: map['consigneeCity'] as String?,
      consigneeState: map['consigneeState'] as String?,
      consigneeCountry: map['consigneeCountry'] as String?,
      consigneeZipCode: map['consigneeZipCode'] as String?,
      // Cargo Details
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      length: (map['length'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      hsCode: map['hsCode'] as String?,
      commodityType: map['commodityType'] as String?,
      packageType: map['packageType'] as String?,
      numberOfPackages: map['numberOfPackages'] as int?,
      unNumber: map['unNumber'] as String?,
      isDangerousGoods: map['isDangerousGoods'] as bool? ?? false,
      isPerishable: map['isPerishable'] as bool? ?? false,
      isFragile: map['isFragile'] as bool? ?? false,
      specialHandling: map['specialHandling'] as String?,
      // Air Freight Specific
      airportOfOrigin: map['airportOfOrigin'] as String?,
      airportOfDestination: map['airportOfDestination'] as String?,
      preferredAirline: map['preferredAirline'] as String?,
      airServiceLevel: map['airServiceLevel'] as String?,
      uldType: map['uldType'] as String?,
      mawbNumber: map['mawbNumber'] as String?,
      hawbNumber: map['hawbNumber'] as String?,
      cargoReadyDate: map['cargoReadyDate'] != null
          ? (map['cargoReadyDate'] as Timestamp).toDate()
          : null,
      expectedShippingDate: map['expectedShippingDate'] != null
          ? (map['expectedShippingDate'] as Timestamp).toDate()
          : null,
      // Sea Freight Specific
      portOfLoading: map['portOfLoading'] as String?,
      portOfDischarge: map['portOfDischarge'] as String?,
      finalDestinationPort: map['finalDestinationPort'] as String?,
      containerType: map['containerType'] as String?,
      containerSize: map['containerSize'] as String?,
      numberOfContainers: map['numberOfContainers'] as int?,
      containerOwnership: map['containerOwnership'] as String?,
      vesselName: map['vesselName'] as String?,
      voyageNumber: map['voyageNumber'] as String?,
      billOfLadingType: map['billOfLadingType'] as String?,
      billOfLadingInstructions: map['billOfLadingInstructions'] as String?,
      transshipmentPoints: map['transshipmentPoints'] as String?,
      preCarriage: map['preCarriage'] as String?,
      onCarriage: map['onCarriage'] as String?,
      lastReceivingDate: map['lastReceivingDate'] != null
          ? (map['lastReceivingDate'] as Timestamp).toDate()
          : null,
      carrierCutoffDate: map['carrierCutoffDate'] != null
          ? (map['carrierCutoffDate'] as Timestamp).toDate()
          : null,
      // Shipping Terms & Services
      incoterms: map['incoterms'] as String?,
      freightPaymentTerms: map['freightPaymentTerms'] as String?,
      insuranceType: map['insuranceType'] as String?,
      insuranceValue: (map['insuranceValue'] as num?)?.toDouble(),
      customsBroker: map['customsBroker'] as String?,
      needsCustomsClearance: map['needsCustomsClearance'] as bool? ?? false,
      // Commercial & Customs
      invoiceNumber: map['invoiceNumber'] as String?,
      invoiceValue: (map['invoiceValue'] as num?)?.toDouble(),
      invoiceCurrency: map['invoiceCurrency'] as String?,
      exportLicenseNumber: map['exportLicenseNumber'] as String?,
      importLicenseNumber: map['importLicenseNumber'] as String?,
      certificateOfOrigin: map['certificateOfOrigin'] as String?,
      // Special Instructions
      specialInstructions: map['specialInstructions'] as String?,
      deliveryInstructions: map['deliveryInstructions'] as String?,
      pickupInstructions: map['pickupInstructions'] as String?,
      // Existing Fields
      estimatedCost: (map['estimatedCost'] as num?)?.toDouble() ?? 0,
      actualCost: (map['actualCost'] as num?)?.toDouble() ?? 0,
      trackingNumber: map['trackingNumber'] as String?,
      carrier: map['carrier'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      estimatedDelivery: map['estimatedDelivery'] != null
          ? (map['estimatedDelivery'] as Timestamp).toDate()
          : null,
      actualDelivery: map['actualDelivery'] != null
          ? (map['actualDelivery'] as Timestamp).toDate()
          : null,
      documents: (map['documents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      insuranceDetails: map['insuranceDetails'] as Map<String, dynamic>? ?? {},
      customsInfo: map['customsInfo'] as Map<String, dynamic>? ?? {},
      performanceMetrics:
          map['performanceMetrics'] as Map<String, dynamic>? ?? {},
      assignedAdminId: map['assignedAdminId'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      affiliateCommission:
          (map['affiliateCommission'] as num?)?.toDouble() ?? 0,
      requiresInsurance: map['requiresInsurance'] as bool? ?? false,
      requiresCustomsClearance:
          map['requiresCustomsClearance'] as bool? ?? false,
      // Submission metadata
      submittedBy: map['submittedBy'] as String?,
      shareToken: map['shareToken'] as String?,
      // Form Share Tracking (NEW)
      formShareToken: map['formShareToken'] as String?,
      formShareTokenEmail: map['formShareTokenEmail'] as String?,
      submissionType: map['submissionType'] as String? ?? 'direct',
      affiliateToken: map['affiliateToken'] as String?,
      affiliateTokenId: map['affiliateTokenId'] as String?,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'affiliateId': affiliateId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'type': type.toJson(),
      'status': status.toJson(),
      'priority': priority.toJson(),
      'origin': origin,
      'destination': destination,
      // Shipper Information
      'shipperType': shipperType,
      'shipperCompanyName': shipperCompanyName,
      'shipperFullName': shipperFullName,
      'shipperEmail': shipperEmail,
      'shipperPhone': shipperPhone,
      'shipperAddressLine1': shipperAddressLine1,
      'shipperAddressLine2': shipperAddressLine2,
      'shipperCity': shipperCity,
      'shipperState': shipperState,
      'shipperCountry': shipperCountry,
      'shipperZipCode': shipperZipCode,
      'shipperTaxId': shipperTaxId,
      'shipperVatNumber': shipperVatNumber,
      // Consignee Information
      'consigneeType': consigneeType,
      'consigneeCompanyName': consigneeCompanyName,
      'consigneeFullName': consigneeFullName,
      'consigneeEmail': consigneeEmail,
      'consigneePhone': consigneePhone,
      'consigneeAddressLine1': consigneeAddressLine1,
      'consigneeAddressLine2': consigneeAddressLine2,
      'consigneeCity': consigneeCity,
      'consigneeState': consigneeState,
      'consigneeCountry': consigneeCountry,
      'consigneeZipCode': consigneeZipCode,
      // Cargo Details
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'description': description,
      'hsCode': hsCode,
      'commodityType': commodityType,
      'packageType': packageType,
      'numberOfPackages': numberOfPackages,
      'unNumber': unNumber,
      'isDangerousGoods': isDangerousGoods,
      'isPerishable': isPerishable,
      'isFragile': isFragile,
      'specialHandling': specialHandling,
      // Air Freight Specific
      'airportOfOrigin': airportOfOrigin,
      'airportOfDestination': airportOfDestination,
      'preferredAirline': preferredAirline,
      'airServiceLevel': airServiceLevel,
      'uldType': uldType,
      'mawbNumber': mawbNumber,
      'hawbNumber': hawbNumber,
      'cargoReadyDate':
          cargoReadyDate != null ? Timestamp.fromDate(cargoReadyDate!) : null,
      'expectedShippingDate': expectedShippingDate != null
          ? Timestamp.fromDate(expectedShippingDate!)
          : null,
      // Sea Freight Specific
      'portOfLoading': portOfLoading,
      'portOfDischarge': portOfDischarge,
      'finalDestinationPort': finalDestinationPort,
      'containerType': containerType,
      'containerSize': containerSize,
      'numberOfContainers': numberOfContainers,
      'containerOwnership': containerOwnership,
      'vesselName': vesselName,
      'voyageNumber': voyageNumber,
      'billOfLadingType': billOfLadingType,
      'billOfLadingInstructions': billOfLadingInstructions,
      'transshipmentPoints': transshipmentPoints,
      'preCarriage': preCarriage,
      'onCarriage': onCarriage,
      'lastReceivingDate': lastReceivingDate != null
          ? Timestamp.fromDate(lastReceivingDate!)
          : null,
      'carrierCutoffDate': carrierCutoffDate != null
          ? Timestamp.fromDate(carrierCutoffDate!)
          : null,
      // Shipping Terms & Services
      'incoterms': incoterms,
      'freightPaymentTerms': freightPaymentTerms,
      'insuranceType': insuranceType,
      'insuranceValue': insuranceValue,
      'customsBroker': customsBroker,
      'needsCustomsClearance': needsCustomsClearance,
      // Commercial & Customs
      'invoiceNumber': invoiceNumber,
      'invoiceValue': invoiceValue,
      'invoiceCurrency': invoiceCurrency,
      'exportLicenseNumber': exportLicenseNumber,
      'importLicenseNumber': importLicenseNumber,
      'certificateOfOrigin': certificateOfOrigin,
      // Special Instructions
      'specialInstructions': specialInstructions,
      'deliveryInstructions': deliveryInstructions,
      'pickupInstructions': pickupInstructions,
      // Existing Fields
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'trackingNumber': trackingNumber,
      'carrier': carrier,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'actualDelivery':
          actualDelivery != null ? Timestamp.fromDate(actualDelivery!) : null,
      'documents': documents,
      'insuranceDetails': insuranceDetails,
      'customsInfo': customsInfo,
      'performanceMetrics': performanceMetrics,
      'assignedAdminId': assignedAdminId,
      'rejectionReason': rejectionReason,
      'affiliateCommission': affiliateCommission,
      'requiresInsurance': requiresInsurance,
      'requiresCustomsClearance': requiresCustomsClearance,
      // Submission metadata
      'submittedBy': submittedBy,
      'shareToken': shareToken,
      // Form Share Tracking (NEW)
      'formShareToken': formShareToken,
      'formShareTokenEmail': formShareTokenEmail,
      'submissionType': submissionType,
      'affiliateToken': affiliateToken,
      'affiliateTokenId': affiliateTokenId,
    };
  }
}
