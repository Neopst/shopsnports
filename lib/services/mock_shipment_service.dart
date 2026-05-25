/// Service for mock shipment operations
class MockShipmentService {
  static final MockShipmentService instance = MockShipmentService._();
  MockShipmentService._();

  Future<void> claimRequest(String requestId, String shipperId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> completeRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}