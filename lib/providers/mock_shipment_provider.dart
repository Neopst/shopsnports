import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock shipment data for shipper dashboard development
final mockShipments = <Map<String, dynamic>>[];

/// Mock shipment stream provider
final shipmentsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Stream.value(mockShipments);
});