/// Mock affiliate service for development and testing
/// This provides fallback implementations when the real API is unavailable
class MockAffiliateService {
  /// Create a shipment link for a client
  Future<String> createShipmentLink({required String affiliateId}) async {
    // Generate a mock token-based URL
    final token = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'https://shopsnports.com/public/shipment-request?token=$token';
  }

  /// Create a shipment on behalf of a client
  Future<Map<String, dynamic>> createShipmentOnBehalf({
    required String affiliateId,
    required Map<String, dynamic> client,
  }) async {
    final token = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return {
      'link': 'https://shopsnports.com/public/shipment-request?token=$token',
      'url': 'https://shopsnports.com/public/shipment-request?token=$token',
      'token': token,
    };
  }

  /// Mark a shipment request as completed
  Future<Map<String, dynamic>?> markRequestCompleted(String requestId) async {
    return {
      'id': requestId,
      'status': 'completed',
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
