import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipping_request.dart';
import '../models/enums.dart';

/// Shipping Firestore Service
/// Saves shipping requests directly to Firestore for admin dashboard processing
class ShippingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'shippingRequests';

  /// Create shipping request in Firestore
  Future<ShippingRequest> createShippingRequest({
    required ShippingType type,
    required String origin,
    required String destination,
    required double weight,
    required String description,
    double? length,
    double? width,
    double? height,
    ShippingPriority? priority,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    bool requiresInsurance = false,
    bool requiresCustomsClearance = false,
    String? userId, // Optional - null for unregistered users
  }) async {
    final now = DateTime.now();

    // Generate unique request ID
    final docRef = _firestore.collection(_collectionName).doc();

    final data = {
      'id': docRef.id,
      'type': type.name,
      'origin': origin,
      'destination': destination,
      'weight': weight,
      'description': description,
      'length': length ?? 0,
      'width': width ?? 0,
      'height': height ?? 0,
      'priority': priority?.name ?? ShippingPriority.standard.name,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'requiresInsurance': requiresInsurance,
      'requiresCustomsClearance': requiresCustomsClearance,
      'requesterId': userId ?? 'guest',
      'status': ShippingStatus.pending.name,
      'estimatedCost': 0.0,
      'actualCost': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isRegisteredUser': userId != null,
      'documents': [],
      'insuranceDetails': {},
      'customsInfo': {},
      'performanceMetrics': {},
      'affiliateCommission': 0.0,
    };

    await docRef.set(data);

    // Return the shipping request
    return ShippingRequest(
      id: docRef.id,
      requesterId: userId ?? 'guest',
      type: type,
      origin: origin,
      destination: destination,
      weight: weight,
      description: description,
      length: length ?? 0,
      width: width ?? 0,
      height: height ?? 0,
      priority: priority ?? ShippingPriority.standard,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      requiresInsurance: requiresInsurance,
      requiresCustomsClearance: requiresCustomsClearance,
      status: ShippingStatus.pending,
      estimatedCost: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get user's shipping requests
  Stream<List<ShippingRequest>> getUserShippingRequests(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShippingRequest.fromMap(doc.data()))
            .toList());
  }

  /// Get all shipping requests (for admin)
  Stream<List<ShippingRequest>> getAllShippingRequests() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShippingRequest.fromMap(doc.data()))
            .toList());
  }

  /// Get single shipping request
  Future<ShippingRequest?> getShippingRequest(String requestId) async {
    final doc =
        await _firestore.collection(_collectionName).doc(requestId).get();
    if (!doc.exists) return null;
    return ShippingRequest.fromMap(doc.data()!);
  }

  /// Update shipping request status (for admin)
  Future<void> updateStatus(String requestId, ShippingStatus status) async {
    await _firestore.collection(_collectionName).doc(requestId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update tracking information (for admin)
  Future<void> updateTracking({
    required String requestId,
    String? trackingNumber,
    String? carrier,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (trackingNumber != null) updates['trackingNumber'] = trackingNumber;
    if (carrier != null) updates['carrier'] = carrier;

    await _firestore.collection(_collectionName).doc(requestId).update(updates);
  }

  /// Create comprehensive shipping request with all industry-standard fields
  Future<ShippingRequest> createShippingRequestComplete({
    required String requesterId,
    String? affiliateId,
    required ShippingType type,
    required ShippingPriority priority,
    required String origin,
    required String destination,
    // Shipper
    required String shipperType,
    required String shipperCompanyName,
    required String shipperFullName,
    required String shipperEmail,
    required String shipperPhone,
    required String shipperAddressLine1,
    required String shipperAddressLine2,
    required String shipperCity,
    required String shipperState,
    required String shipperCountry,
    required String shipperZipCode,
    required String shipperTaxId,
    required String shipperVatNumber,
    // Consignee
    required String consigneeType,
    required String consigneeCompanyName,
    required String consigneeFullName,
    required String consigneeEmail,
    required String consigneePhone,
    required String consigneeAddressLine1,
    required String consigneeAddressLine2,
    required String consigneeCity,
    required String consigneeState,
    required String consigneeCountry,
    required String consigneeZipCode,
    // Cargo
    required double weight,
    required double length,
    required double width,
    required double height,
    required String description,
    required String hsCode,
    required String commodityType,
    required String packageType,
    int? numberOfPackages,
    required String unNumber,
    required bool isDangerousGoods,
    required bool isPerishable,
    required bool isFragile,
    required String specialHandling,
    // Air specific
    String? airportOfOrigin,
    String? airportOfDestination,
    required String preferredAirline,
    required String airServiceLevel,
    required String uldType,
    required String mawbNumber,
    required String hawbNumber,
    DateTime? cargoReadyDate,
    DateTime? expectedShippingDate,
    // Sea specific
    String? portOfLoading,
    String? portOfDischarge,
    required String finalDestinationPort,
    required String containerType,
    required String containerSize,
    int? numberOfContainers,
    required String containerOwnership,
    required String vesselName,
    required String voyageNumber,
    required String billOfLadingType,
    required String billOfLadingInstructions,
    required String transshipmentPoints,
    required String preCarriage,
    required String onCarriage,
    DateTime? lastReceivingDate,
    DateTime? carrierCutoffDate,
    // Terms
    required String incoterms,
    required String freightPaymentTerms,
    required String insuranceType,
    double? insuranceValue,
    required String customsBroker,
    required bool needsCustomsClearance,
    // Commercial
    required String invoiceNumber,
    double? invoiceValue,
    required String invoiceCurrency,
    required String exportLicenseNumber,
    required String importLicenseNumber,
    required String certificateOfOrigin,
    // Instructions
    required String specialInstructions,
    required String deliveryInstructions,
    required String pickupInstructions,
    // Metadata
    String? submittedBy,
    String? shareToken,
    List<String>? documents,
  }) async {
    final docRef = _firestore.collection(_collectionName).doc();
    final now = DateTime.now();

    final data = {
      'id': docRef.id,
      'requesterId': requesterId,
      'affiliateId': affiliateId,
      'type': type.toJson(),
      'status': ShippingStatus.pending.toJson(),
      'priority': priority.toJson(),
      'origin': origin,
      'destination': destination,
      // Shipper
      'shipperType': shipperType.isNotEmpty ? shipperType : null,
      'shipperCompanyName':
          shipperCompanyName.isNotEmpty ? shipperCompanyName : null,
      'shipperFullName': shipperFullName.isNotEmpty ? shipperFullName : null,
      'shipperEmail': shipperEmail.isNotEmpty ? shipperEmail : null,
      'shipperPhone': shipperPhone.isNotEmpty ? shipperPhone : null,
      'shipperAddressLine1':
          shipperAddressLine1.isNotEmpty ? shipperAddressLine1 : null,
      'shipperAddressLine2':
          shipperAddressLine2.isNotEmpty ? shipperAddressLine2 : null,
      'shipperCity': shipperCity.isNotEmpty ? shipperCity : null,
      'shipperState': shipperState.isNotEmpty ? shipperState : null,
      'shipperCountry': shipperCountry.isNotEmpty ? shipperCountry : null,
      'shipperZipCode': shipperZipCode.isNotEmpty ? shipperZipCode : null,
      'shipperTaxId': shipperTaxId.isNotEmpty ? shipperTaxId : null,
      'shipperVatNumber': shipperVatNumber.isNotEmpty ? shipperVatNumber : null,
      // Consignee
      'consigneeType': consigneeType.isNotEmpty ? consigneeType : null,
      'consigneeCompanyName':
          consigneeCompanyName.isNotEmpty ? consigneeCompanyName : null,
      'consigneeFullName':
          consigneeFullName.isNotEmpty ? consigneeFullName : null,
      'consigneeEmail': consigneeEmail.isNotEmpty ? consigneeEmail : null,
      'consigneePhone': consigneePhone.isNotEmpty ? consigneePhone : null,
      'consigneeAddressLine1':
          consigneeAddressLine1.isNotEmpty ? consigneeAddressLine1 : null,
      'consigneeAddressLine2':
          consigneeAddressLine2.isNotEmpty ? consigneeAddressLine2 : null,
      'consigneeCity': consigneeCity.isNotEmpty ? consigneeCity : null,
      'consigneeState': consigneeState.isNotEmpty ? consigneeState : null,
      'consigneeCountry': consigneeCountry.isNotEmpty ? consigneeCountry : null,
      'consigneeZipCode': consigneeZipCode.isNotEmpty ? consigneeZipCode : null,
      // Cargo
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'description': description,
      'hsCode': hsCode.isNotEmpty ? hsCode : null,
      'commodityType': commodityType.isNotEmpty ? commodityType : null,
      'packageType': packageType.isNotEmpty ? packageType : null,
      'numberOfPackages': numberOfPackages,
      'unNumber': unNumber.isNotEmpty ? unNumber : null,
      'isDangerousGoods': isDangerousGoods,
      'isPerishable': isPerishable,
      'isFragile': isFragile,
      'specialHandling': specialHandling.isNotEmpty ? specialHandling : null,
      // Air
      'airportOfOrigin': airportOfOrigin,
      'airportOfDestination': airportOfDestination,
      'preferredAirline': preferredAirline.isNotEmpty ? preferredAirline : null,
      'airServiceLevel': airServiceLevel.isNotEmpty ? airServiceLevel : null,
      'uldType': uldType.isNotEmpty ? uldType : null,
      'mawbNumber': mawbNumber.isNotEmpty ? mawbNumber : null,
      'hawbNumber': hawbNumber.isNotEmpty ? hawbNumber : null,
      'cargoReadyDate':
          cargoReadyDate != null ? Timestamp.fromDate(cargoReadyDate) : null,
      'expectedShippingDate': expectedShippingDate != null
          ? Timestamp.fromDate(expectedShippingDate)
          : null,
      // Sea
      'portOfLoading': portOfLoading,
      'portOfDischarge': portOfDischarge,
      'finalDestinationPort':
          finalDestinationPort.isNotEmpty ? finalDestinationPort : null,
      'containerType': containerType.isNotEmpty ? containerType : null,
      'containerSize': containerSize.isNotEmpty ? containerSize : null,
      'numberOfContainers': numberOfContainers,
      'containerOwnership':
          containerOwnership.isNotEmpty ? containerOwnership : null,
      'vesselName': vesselName.isNotEmpty ? vesselName : null,
      'voyageNumber': voyageNumber.isNotEmpty ? voyageNumber : null,
      'billOfLadingType': billOfLadingType.isNotEmpty ? billOfLadingType : null,
      'billOfLadingInstructions':
          billOfLadingInstructions.isNotEmpty ? billOfLadingInstructions : null,
      'transshipmentPoints':
          transshipmentPoints.isNotEmpty ? transshipmentPoints : null,
      'preCarriage': preCarriage.isNotEmpty ? preCarriage : null,
      'onCarriage': onCarriage.isNotEmpty ? onCarriage : null,
      'lastReceivingDate': lastReceivingDate != null
          ? Timestamp.fromDate(lastReceivingDate)
          : null,
      'carrierCutoffDate': carrierCutoffDate != null
          ? Timestamp.fromDate(carrierCutoffDate)
          : null,
      // Terms
      'incoterms': incoterms.isNotEmpty ? incoterms : null,
      'freightPaymentTerms':
          freightPaymentTerms.isNotEmpty ? freightPaymentTerms : null,
      'insuranceType': insuranceType.isNotEmpty ? insuranceType : null,
      'insuranceValue': insuranceValue,
      'customsBroker': customsBroker.isNotEmpty ? customsBroker : null,
      'needsCustomsClearance': needsCustomsClearance,
      // Commercial
      'invoiceNumber': invoiceNumber.isNotEmpty ? invoiceNumber : null,
      'invoiceValue': invoiceValue,
      'invoiceCurrency': invoiceCurrency.isNotEmpty ? invoiceCurrency : null,
      'exportLicenseNumber':
          exportLicenseNumber.isNotEmpty ? exportLicenseNumber : null,
      'importLicenseNumber':
          importLicenseNumber.isNotEmpty ? importLicenseNumber : null,
      'certificateOfOrigin':
          certificateOfOrigin.isNotEmpty ? certificateOfOrigin : null,
      // Instructions
      'specialInstructions':
          specialInstructions.isNotEmpty ? specialInstructions : null,
      'deliveryInstructions':
          deliveryInstructions.isNotEmpty ? deliveryInstructions : null,
      'pickupInstructions':
          pickupInstructions.isNotEmpty ? pickupInstructions : null,
      // Standard fields
      'estimatedCost': 0.0,
      'actualCost': 0.0,
      'affiliateCommission': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'documents': documents ?? [],
      'insuranceDetails': {},
      'customsInfo': {},
      'performanceMetrics': {},
      'submittedBy': submittedBy,
      'shareToken': shareToken,
    };

    await docRef.set(data);

    return ShippingRequest(
      id: docRef.id,
      requesterId: requesterId,
      affiliateId: affiliateId,
      type: type,
      status: ShippingStatus.pending,
      priority: priority,
      origin: origin,
      destination: destination,
      shipperType: shipperType.isNotEmpty ? shipperType : null,
      shipperCompanyName:
          shipperCompanyName.isNotEmpty ? shipperCompanyName : null,
      shipperFullName: shipperFullName.isNotEmpty ? shipperFullName : null,
      shipperEmail: shipperEmail.isNotEmpty ? shipperEmail : null,
      shipperPhone: shipperPhone.isNotEmpty ? shipperPhone : null,
      shipperAddressLine1:
          shipperAddressLine1.isNotEmpty ? shipperAddressLine1 : null,
      shipperAddressLine2:
          shipperAddressLine2.isNotEmpty ? shipperAddressLine2 : null,
      shipperCity: shipperCity.isNotEmpty ? shipperCity : null,
      shipperState: shipperState.isNotEmpty ? shipperState : null,
      shipperCountry: shipperCountry.isNotEmpty ? shipperCountry : null,
      shipperZipCode: shipperZipCode.isNotEmpty ? shipperZipCode : null,
      shipperTaxId: shipperTaxId.isNotEmpty ? shipperTaxId : null,
      shipperVatNumber: shipperVatNumber.isNotEmpty ? shipperVatNumber : null,
      consigneeType: consigneeType.isNotEmpty ? consigneeType : null,
      consigneeCompanyName:
          consigneeCompanyName.isNotEmpty ? consigneeCompanyName : null,
      consigneeFullName:
          consigneeFullName.isNotEmpty ? consigneeFullName : null,
      consigneeEmail: consigneeEmail.isNotEmpty ? consigneeEmail : null,
      consigneePhone: consigneePhone.isNotEmpty ? consigneePhone : null,
      consigneeAddressLine1:
          consigneeAddressLine1.isNotEmpty ? consigneeAddressLine1 : null,
      consigneeAddressLine2:
          consigneeAddressLine2.isNotEmpty ? consigneeAddressLine2 : null,
      consigneeCity: consigneeCity.isNotEmpty ? consigneeCity : null,
      consigneeState: consigneeState.isNotEmpty ? consigneeState : null,
      consigneeCountry: consigneeCountry.isNotEmpty ? consigneeCountry : null,
      consigneeZipCode: consigneeZipCode.isNotEmpty ? consigneeZipCode : null,
      weight: weight,
      length: length,
      width: width,
      height: height,
      description: description,
      hsCode: hsCode.isNotEmpty ? hsCode : null,
      commodityType: commodityType.isNotEmpty ? commodityType : null,
      packageType: packageType.isNotEmpty ? packageType : null,
      numberOfPackages: numberOfPackages,
      unNumber: unNumber.isNotEmpty ? unNumber : null,
      isDangerousGoods: isDangerousGoods,
      isPerishable: isPerishable,
      isFragile: isFragile,
      specialHandling: specialHandling.isNotEmpty ? specialHandling : null,
      airportOfOrigin: airportOfOrigin,
      airportOfDestination: airportOfDestination,
      preferredAirline: preferredAirline.isNotEmpty ? preferredAirline : null,
      airServiceLevel: airServiceLevel.isNotEmpty ? airServiceLevel : null,
      uldType: uldType.isNotEmpty ? uldType : null,
      mawbNumber: mawbNumber.isNotEmpty ? mawbNumber : null,
      hawbNumber: hawbNumber.isNotEmpty ? hawbNumber : null,
      cargoReadyDate: cargoReadyDate,
      expectedShippingDate: expectedShippingDate,
      portOfLoading: portOfLoading,
      portOfDischarge: portOfDischarge,
      finalDestinationPort:
          finalDestinationPort.isNotEmpty ? finalDestinationPort : null,
      containerType: containerType.isNotEmpty ? containerType : null,
      containerSize: containerSize.isNotEmpty ? containerSize : null,
      numberOfContainers: numberOfContainers,
      containerOwnership:
          containerOwnership.isNotEmpty ? containerOwnership : null,
      vesselName: vesselName.isNotEmpty ? vesselName : null,
      voyageNumber: voyageNumber.isNotEmpty ? voyageNumber : null,
      billOfLadingType: billOfLadingType.isNotEmpty ? billOfLadingType : null,
      billOfLadingInstructions:
          billOfLadingInstructions.isNotEmpty ? billOfLadingInstructions : null,
      transshipmentPoints:
          transshipmentPoints.isNotEmpty ? transshipmentPoints : null,
      preCarriage: preCarriage.isNotEmpty ? preCarriage : null,
      onCarriage: onCarriage.isNotEmpty ? onCarriage : null,
      lastReceivingDate: lastReceivingDate,
      carrierCutoffDate: carrierCutoffDate,
      incoterms: incoterms.isNotEmpty ? incoterms : null,
      freightPaymentTerms:
          freightPaymentTerms.isNotEmpty ? freightPaymentTerms : null,
      insuranceType: insuranceType.isNotEmpty ? insuranceType : null,
      insuranceValue: insuranceValue,
      customsBroker: customsBroker.isNotEmpty ? customsBroker : null,
      needsCustomsClearance: needsCustomsClearance,
      invoiceNumber: invoiceNumber.isNotEmpty ? invoiceNumber : null,
      invoiceValue: invoiceValue,
      invoiceCurrency: invoiceCurrency.isNotEmpty ? invoiceCurrency : null,
      exportLicenseNumber:
          exportLicenseNumber.isNotEmpty ? exportLicenseNumber : null,
      importLicenseNumber:
          importLicenseNumber.isNotEmpty ? importLicenseNumber : null,
      certificateOfOrigin:
          certificateOfOrigin.isNotEmpty ? certificateOfOrigin : null,
      specialInstructions:
          specialInstructions.isNotEmpty ? specialInstructions : null,
      deliveryInstructions:
          deliveryInstructions.isNotEmpty ? deliveryInstructions : null,
      pickupInstructions:
          pickupInstructions.isNotEmpty ? pickupInstructions : null,
      estimatedCost: 0.0,
      createdAt: now,
      documents: documents ?? [],
      submittedBy: submittedBy,
      shareToken: shareToken,
    );
  }
}
