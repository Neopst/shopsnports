// lib/features/orders/data/order_repository.dart

import 'package:dio/dio.dart';
import 'package:admin_dashboard/core/network/dio_client.dart';

class OrderRepository {
  final Dio _dio = DioClient.instance.dio;

  /// Fetch all orders
  Future<List<dynamic>> fetchOrders() async {
    try {
      final response = await _dio.get('/orders');
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single order by ID
  Future<Map<String, dynamic>> fetchOrderById(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(
    String id,
    Map<String, dynamic> statusData,
  ) async {
    try {
      final response = await _dio.patch('/orders/$id/status', data: statusData);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String id) async {
    try {
      await _dio.delete('/orders/$id');
    } catch (e) {
      rethrow;
    }
  }
}
