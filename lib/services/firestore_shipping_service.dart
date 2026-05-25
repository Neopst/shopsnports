import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:math';
import '../models/shipping_request_simple.dart';

/// Service for handling shipping request operations with Firebase/Firestore
/// This is the ONLY backend service - no REST API, pure Firebase
class FirestoreShippingService {
  static final FirestoreShippingService _instance =
      FirestoreShippingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirestoreShippingService._internal();

  factory FirestoreShippingService() {
    return _instance;
  }

  static const String _shippingRequestsCollection = 'shippingRequests';
  static const String _notificationsCollection = 'notifications';

  /// Generate a unique tracking number
  /// Format: SHP-YYYYMMDD-XXXXX (where XXXXX is random alphanumeric)
  String _generateTrackingNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomStr =
        List.generate(5, (index) => chars[random.nextInt(chars.length)]).join();
    return 'SHP-$dateStr-$randomStr';
  }

  /// Submit a new shipping request directly to Firestore
  /// Returns the document ID of the created request
  Future<String> submitShippingRequest(
    SimpleShippingRequest request,
  ) async {
    try {
      // Generate tracking number immediately
      final trackingNumber = _generateTrackingNumber();

      // Generation of ID: Use Firestore auto-generated ID, then update in model
      final payload = request.toFirestore();
      payload['trackingNumber'] = trackingNumber;
      final docRef =
          await _firestore.collection(_shippingRequestsCollection).add(payload);

      // Update the ID field in the document to match the auto-generated ID
      await docRef.update({'id': docRef.id});

      // Create notification for admin
      await _createAdminNotification(docRef.id, request.senderName);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit shipping request: $e');
    }
  }

  /// Upload documents to Firebase Storage
  /// Returns list of download URLs
  Future<List<String>> uploadDocuments(
    String requestId,
    List<File> files,
  ) async {
    try {
      final List<String> urls = [];

      for (final file in files) {
        final filename = file.path.split('/').last;
        final storageRef = _storage
            .ref()
            .child('shipping_requests')
            .child(requestId)
            .child(filename);

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to upload documents: $e');
    }
  }

  /// Create admin notification when new request is submitted
  Future<void> _createAdminNotification(
    String requestId,
    String senderName,
  ) async {
    try {
      await _firestore.collection(_notificationsCollection).add({
        'type': 'new_shipping_request',
        'requestId': requestId,
        'senderName': senderName,
        'targetRole': 'admin',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'message': 'New shipping request from $senderName',
      });
    } catch (e) {
      // Silent notification failure
    }
  }

  /// Get shipping request by ID
  Future<Map<String, dynamic>?> getShippingRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_shippingRequestsCollection)
          .doc(requestId)
          .get();

      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch shipping request: $e');
    }
  }

  /// Get all shipping requests for a user
  Future<List<Map<String, dynamic>>> getUserShippingRequests(
    String userEmail,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_shippingRequestsCollection)
          .where('senderEmail', isEqualTo: userEmail)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch user shipping requests: $e');
    }
  }

  /// Update shipping request status (admin only)
  Future<void> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(_shippingRequestsCollection)
          .doc(requestId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  /// Assign request to a shipper (admin only)
  Future<void> assignRequestToShipper(
    String requestId,
    String shipperId,
  ) async {
    try {
      await _firestore
          .collection(_shippingRequestsCollection)
          .doc(requestId)
          .update({
        'assignedTo': shipperId,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign request: $e');
    }
  }

  /// Tag affiliate to request (for commission tracking)
  Future<void> tagAffiliateToRequest(
    String requestId,
    String affiliateId,
  ) async {
    try {
      await _firestore
          .collection(_shippingRequestsCollection)
          .doc(requestId)
          .update({
        'affiliate': affiliateId,
        'affiliateTaggedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to tag affiliate: $e');
    }
  }

  /// Stream of all shipping requests (for admin dashboard)
  Stream<List<Map<String, dynamic>>> getShippingRequestsStream() {
    return _firestore
        .collection(_shippingRequestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Stream of pending requests only
  Stream<List<Map<String, dynamic>>> getPendingRequestsStream() {
    return _firestore
        .collection(_shippingRequestsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
