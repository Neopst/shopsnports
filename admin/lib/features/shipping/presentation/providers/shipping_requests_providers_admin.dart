import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/shipping_request_simplified_model.dart';
import '../../data/shipping_email_service.dart';

/// Admin provider for querying the new shippingRequests collection
/// Uses ShippingRequestSimplified model (21 fields)

final _firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

/// Provider to stream all shipping requests (real-time)
final adminAllShippingRequestsProvider =
    StreamProvider<List<ShippingRequestSimplified>>((ref) {
      final firestore = ref.watch(_firestoreProvider);

      return firestore
          .collection('shippingRequests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => ShippingRequestSimplified.fromFirestore(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();
          });
    });

/// Provider to stream single shipping request by ID
final adminShippingRequestProvider =
    StreamProvider.family<ShippingRequestSimplified?, String>((ref, requestId) {
      final firestore = ref.watch(_firestoreProvider);

      return firestore
          .collection('shippingRequests')
          .doc(requestId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return ShippingRequestSimplified.fromFirestore(doc.data()!, doc.id);
          });
    });

/// Provider to stream requests by status
final adminShippingRequestsByStatusProvider =
    StreamProvider.family<List<ShippingRequestSimplified>, String>(
      (ref, status) {
        final firestore = ref.watch(_firestoreProvider);

        return firestore
            .collection('shippingRequests')
            .where('status', isEqualTo: status)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map(
                    (doc) => ShippingRequestSimplified.fromFirestore(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList();
            });
      });

/// Provider to get shipping stats
final adminShippingStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final firestore = ref.watch(_firestoreProvider);

  return firestore.collection('shippingRequests').snapshots().asyncMap(
    (snapshot) async {
      final docs = snapshot.docs;
      final requests = docs
          .map(
            (doc) => ShippingRequestSimplified.fromFirestore(doc.data(), doc.id),
          )
          .toList();

      final stats = {
        'total': requests.length,
        'pending': requests.where((r) => r.status == 'pending').length,
        'approved': requests.where((r) => r.status == 'approved').length,
        'in_transit': requests.where((r) => r.status == 'in_transit').length,
        'delivered': requests.where((r) => r.status == 'delivered').length,
        'cancelled': requests.where((r) => r.status == 'cancelled').length,
        'total_weight': requests.fold<double>(
          0,
          (sum, r) => sum + r.shipmentWeight,
        ),
      };

      return stats;
    });
});

/// Notifier for admin actions (update status, assign tracking, etc.)
class AdminShippingActionsNotifier extends AsyncNotifier<void> {
  late final FirebaseFirestore _firestore;
  late final ShippingEmailService _emailService;

  @override
  Future<void> build() async {
    _firestore = ref.watch(_firestoreProvider);
    _emailService = ShippingEmailService(firestore: _firestore);
  }

  /// Update shipping request status and send email notification
  Future<void> updateStatus(
    String requestId,
    String newStatus, {
    bool sendEmailNotification = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get current request to capture old status for email
      final requestDoc = await _firestore
          .collection('shippingRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Shipping request not found');
      }

      final requestData = requestDoc.data()!;
      final oldStatus = requestData['status'] as String? ?? 'pending';
      final senderEmail = requestData['senderEmail'] as String? ?? '';
      final senderName = requestData['senderName'] as String? ?? 'Customer';
      final trackingNumber = requestData['trackingNumber'] as String?;
      final category = requestData['category'] as String? ?? 'guest';
      final affiliateId = requestData['affiliateId'] as String?;

      // Update status in Firestore
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email notification if enabled
      if (sendEmailNotification) {
        // Notify sender (customer/guest)
        if (senderEmail.isNotEmpty) {
          try {
            await _emailService.sendShippingStatusUpdate(
              toEmail: senderEmail,
              customerName: senderName,
              requestId: requestId,
              oldStatus: oldStatus,
              newStatus: newStatus,
              trackingNumber: trackingNumber,
            );
          } catch (emailError) {
            // Log email error but don't fail the status update
            AppLogger.error('Failed to send status update email to sender: $emailError', tag: 'Email');
          }
        }

        // Notify affiliate if this is an affiliate request
        if (category == 'affiliate' && affiliateId != null) {
          try {
            final affiliateDoc = await _firestore
                .collection('affiliates')
                .doc(affiliateId)
                .get();

            if (affiliateDoc.exists) {
              final affiliateData = affiliateDoc.data()!;
              final affiliateEmail = affiliateData['email'] as String?;
              final affiliateName = affiliateData['fullName'] as String? ?? 'Affiliate';

              if (affiliateEmail != null && affiliateEmail.isNotEmpty) {
                await _emailService.sendShippingStatusUpdate(
                  toEmail: affiliateEmail,
                  customerName: affiliateName,
                  requestId: requestId,
                  oldStatus: oldStatus,
                  newStatus: newStatus,
                  trackingNumber: trackingNumber,
                  additionalInfo: 'This is an affiliate shipping request.',
                );
              }
            }
          } catch (affiliateError) {
            // Log affiliate notification error but don't fail the status update
            AppLogger.error('Failed to send status update email to affiliate: $affiliateError', tag: 'Email');
          }
        }
      }

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Assign tracking number and send email notification
  Future<void> assignTrackingNumber(
    String requestId,
    String trackingNumber, {
    bool sendEmailNotification = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get current request data
      final requestDoc = await _firestore
          .collection('shippingRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Shipping request not found');
      }

      final requestData = requestDoc.data()!;
      final senderEmail = requestData['senderEmail'] as String? ?? '';
      final senderName = requestData['senderName'] as String? ?? 'Customer';
      final category = requestData['category'] as String? ?? 'guest';
      final affiliateId = requestData['affiliateId'] as String?;

      // Update tracking number in Firestore
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'trackingNumber': trackingNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email notification if enabled
      if (sendEmailNotification) {
        // Notify sender (customer/guest)
        if (senderEmail.isNotEmpty) {
          try {
            await _emailService.sendTrackingNumberAssigned(
              toEmail: senderEmail,
              customerName: senderName,
              requestId: requestId,
              trackingNumber: trackingNumber,
            );
          } catch (emailError) {
            AppLogger.error('Failed to send tracking email to sender: $emailError', tag: 'Email');
          }
        }

        // Notify affiliate if this is an affiliate request
        if (category == 'affiliate' && affiliateId != null) {
          try {
            final affiliateDoc = await _firestore
                .collection('affiliates')
                .doc(affiliateId)
                .get();

            if (affiliateDoc.exists) {
              final affiliateData = affiliateDoc.data()!;
              final affiliateEmail = affiliateData['email'] as String?;
              final affiliateName = affiliateData['fullName'] as String? ?? 'Affiliate';

              if (affiliateEmail != null && affiliateEmail.isNotEmpty) {
                await _emailService.sendTrackingNumberAssigned(
                  toEmail: affiliateEmail,
                  customerName: affiliateName,
                  requestId: requestId,
                  trackingNumber: trackingNumber,
                );
              }
            }
          } catch (affiliateError) {
            AppLogger.error('Failed to send tracking email to affiliate: $affiliateError', tag: 'Email');
          }
        }
      }

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Assign admin to request
  Future<void> assignAdmin(String requestId, String adminId) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'assignedAdminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Set estimated cost
  Future<void> setEstimatedCost(String requestId, double cost) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'estimatedCost': cost,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Set actual cost
  Future<void> setActualCost(String requestId, double cost) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'actualCost': cost,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Reject request with reason and send email notification
  Future<void> rejectRequest(
    String requestId,
    String rejectionReason, {
    bool sendEmailNotification = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get current request data
      final requestDoc = await _firestore
          .collection('shippingRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Shipping request not found');
      }

      final requestData = requestDoc.data()!;
      final senderEmail = requestData['senderEmail'] as String? ?? '';
      final senderName = requestData['senderName'] as String? ?? 'Customer';
      final category = requestData['category'] as String? ?? 'guest';
      final affiliateId = requestData['affiliateId'] as String?;

      // Update status in Firestore
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'status': 'cancelled',
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send rejection email if enabled
      if (sendEmailNotification) {
        // Notify sender (customer/guest)
        if (senderEmail.isNotEmpty) {
          try {
            await _emailService.sendShippingStatusUpdate(
              toEmail: senderEmail,
              customerName: senderName,
              requestId: requestId,
              oldStatus: 'pending',
              newStatus: 'cancelled',
              additionalInfo: 'Reason: $rejectionReason',
            );
          } catch (emailError) {
            AppLogger.error('Failed to send rejection email to sender: $emailError', tag: 'Email');
          }
        }

        // Notify affiliate if this is an affiliate request
        if (category == 'affiliate' && affiliateId != null) {
          try {
            final affiliateDoc = await _firestore
                .collection('affiliates')
                .doc(affiliateId)
                .get();

            if (affiliateDoc.exists) {
              final affiliateData = affiliateDoc.data()!;
              final affiliateEmail = affiliateData['email'] as String?;
              final affiliateName = affiliateData['fullName'] as String? ?? 'Affiliate';

              if (affiliateEmail != null && affiliateEmail.isNotEmpty) {
                await _emailService.sendShippingStatusUpdate(
                  toEmail: affiliateEmail,
                  customerName: affiliateName,
                  requestId: requestId,
                  oldStatus: 'pending',
                  newStatus: 'cancelled',
                  additionalInfo: 'Reason: $rejectionReason (Affiliate Request)',
                );
              }
            }
          } catch (affiliateError) {
            AppLogger.error('Failed to send rejection email to affiliate: $affiliateError', tag: 'Email');
          }
        }
      }

      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  /// Manually update the category
  Future<void> updateCategory(String requestId, String category) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.collection('shippingRequests').doc(requestId).update({
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

/// Provider for admin actions
final adminShippingActionsProvider =
    AsyncNotifierProvider<AdminShippingActionsNotifier, void>(
      AdminShippingActionsNotifier.new,
    );