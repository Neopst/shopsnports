import '../models/shipping_request.dart';
import '../models/tracking_info.dart';
import '../models/enums.dart';
import 'shipping_firestore_service.dart';

class ShippingApiService {
  final ShippingFirestoreService _firestore = ShippingFirestoreService();

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
  }) async {
    return _firestore.createShippingRequest(
      type: type,
      origin: origin,
      destination: destination,
      weight: weight,
      description: description,
      length: length,
      width: width,
      height: height,
      priority: priority,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      requiresInsurance: requiresInsurance,
      requiresCustomsClearance: requiresCustomsClearance,
    );
  }

  Future<TrackingInfo?> getTracking(String requestId) async {
    final shippingRequest = await _firestore.getShippingRequest(requestId);
    if (shippingRequest == null) return null;

    return TrackingInfo(
      trackingNumber: shippingRequest.trackingNumber ?? 'N/A',
      carrier: shippingRequest.carrier,
      status: shippingRequest.status,
      origin: shippingRequest.origin,
      destination: shippingRequest.destination,
      estimatedDelivery: shippingRequest.estimatedDelivery,
      actualDelivery: shippingRequest.actualDelivery,
      events: [],
    );
  }
}
