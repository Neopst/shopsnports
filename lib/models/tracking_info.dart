import 'package:shopsnports/models/enums.dart';

class TrackingEvent {
  final String description;
  final String location;
  final DateTime timestamp;

  TrackingEvent({
    required this.description,
    required this.location,
    required this.timestamp,
  });
}

class TrackingInfo {
  final String trackingNumber;
  final String? carrier;
  final ShippingStatus status;
  final String origin;
  final String destination;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final List<TrackingEvent> events;

  TrackingInfo({
    required this.trackingNumber,
    this.carrier,
    required this.status,
    required this.origin,
    required this.destination,
    this.estimatedDelivery,
    this.actualDelivery,
    this.events = const [],
  });
}
