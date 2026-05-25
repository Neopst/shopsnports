import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/shipping_request_model.dart';

class ShippingRepositoryFirestore {
  final FirebaseFirestore _firestore;
  static const String _collection =
      'shippingRequests'; // Fixed: was 'shipments'

  ShippingRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get all shipping requests with optional filters
  Future<Map<String, dynamic>> getShippingRequests({
    int page = 1,
    int limit = 20,
    String? status,
    String? shippingType,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply filters
      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      if (shippingType != null) {
        query = query.where('type', isEqualTo: shippingType);
      }

      // Order by creation date
      query = query.orderBy('createdAt', descending: true);

      // For simple pagination without cursor, we'll fetch all and slice
      // (For production, use startAfterDocument cursor-based pagination)
      final snapshot = await query.get();
      final allDocs = snapshot.docs;
      final total = allDocs.length;

      // Apply client-side pagination
      final offset = (page - 1) * limit;
      final paginatedDocs = allDocs.skip(offset).take(limit).toList();

      final data = paginatedDocs
          .map((doc) => ShippingRequest.fromFirestore(doc).toMap())
          .toList();

      return {
        'shipping_requests':
            data, // Changed from 'data' to match UI expectations
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'totalPages': (total / limit).ceil(),
        },
      };
    } catch (e) {
      throw Exception('Failed to fetch shipping requests: $e');
    }
  }

  // Get single shipping request
  Future<Map<String, dynamic>> getShippingRequestById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Shipping request not found');
      }
      return ShippingRequest.fromFirestore(doc).toMap();
    } catch (e) {
      throw Exception('Failed to fetch shipping request: $e');
    }
  }

  // Create shipping request
  Future<Map<String, dynamic>> createShippingRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final request = ShippingRequest(
        id: docRef.id,
        requesterId: data['requesterId'] ?? '',
        affiliateId: data['affiliateId'],
        clientName: data['clientName'],
        clientEmail: data['clientEmail'],
        clientPhone: data['clientPhone'],
        type: ShippingType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => ShippingType.air,
        ),
        status: ShippingStatus.pending,
        priority: ShippingPriority.values.firstWhere(
          (e) => e.name == data['priority'],
          orElse: () => ShippingPriority.standard,
        ),
        origin: data['origin'] ?? '',
        destination: data['destination'] ?? '',
        weight: (data['weight'] ?? 0).toDouble(),
        length: (data['length'] ?? 0).toDouble(),
        width: (data['width'] ?? 0).toDouble(),
        height: (data['height'] ?? 0).toDouble(),
        description: data['description'] ?? '',
        estimatedCost: (data['estimatedCost'] ?? 0).toDouble(),
        createdAt: DateTime.now(),
      );

      await docRef.set(request.toMap());
      return request.toMap();
    } catch (e) {
      throw Exception('Failed to create shipping request: $e');
    }
  }

  // Update shipping request
  Future<Map<String, dynamic>> updateShippingRequest(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection(_collection).doc(id).update(data);
      return await getShippingRequestById(id);
    } catch (e) {
      throw Exception('Failed to update shipping request: $e');
    }
  }

  // Delete shipping request
  Future<void> deleteShippingRequest(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete shipping request: $e');
    }
  }

  // Update status
  Future<Map<String, dynamic>> updateStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return await getShippingRequestById(id);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Update document status (verify/reject)
  Future<void> updateDocumentStatus(
    String requestId,
    String documentId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (!doc.exists) throw Exception('Shipping request not found');

      final data = doc.data()!;
      final documents = List<Map<String, dynamic>>.from(
        data['documents'] ?? [],
      );

      final index = documents.indexWhere((d) => d['id'] == documentId);
      if (index == -1) throw Exception('Document not found');

      documents[index]['status'] = status;
      if (rejectionReason != null) {
        documents[index]['rejectionReason'] = rejectionReason;
      }

      await _firestore.collection(_collection).doc(requestId).update({
        'documents': documents,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update document status: $e');
    }
  }

  // Delete document
  Future<void> deleteDocument(String requestId, String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      if (!doc.exists) throw Exception('Shipping request not found');

      final data = doc.data()!;
      final documents = List<Map<String, dynamic>>.from(
        data['documents'] ?? [],
      );

      documents.removeWhere((d) => d['id'] == documentId);

      await _firestore.collection(_collection).doc(requestId).update({
        'documents': documents,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Get stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final requests = snapshot.docs
          .map((doc) => ShippingRequest.fromFirestore(doc))
          .toList();

      return {
        'total': requests.length,
        'pending': requests
            .where((r) => r.status == ShippingStatus.pending)
            .length,
        'approved': requests
            .where((r) => r.status == ShippingStatus.approved)
            .length,
        'inTransit': requests
            .where((r) => r.status == ShippingStatus.inTransit)
            .length,
        'delivered': requests
            .where((r) => r.status == ShippingStatus.delivered)
            .length,
        'cancelled': requests
            .where((r) => r.status == ShippingStatus.cancelled)
            .length,
        'totalRevenue': requests.fold<double>(
          0,
          (sum, r) => sum + r.actualCost,
        ),
        'totalWeight': requests.fold<double>(0, (sum, r) => sum + r.weight),
      };
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }
}
