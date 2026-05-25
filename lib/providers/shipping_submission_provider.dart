import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/models/shipping_request_simplified.dart';
import 'package:shopsnports/services/shipping_email_notification_service.dart';
import 'dart:math';

/// Mobile-specific notifier for submitting shipping requests
/// Handles form submission, validation, and Firestore operations
class ShippingSubmissionNotifier extends StateNotifier<AsyncValue<void>> {
  final ShippingEmailNotificationService _emailService;

  ShippingSubmissionNotifier()
      : _emailService = ShippingEmailNotificationService(),
      super(const AsyncValue.data(null));

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

  /// Submit a new shipping request
  /// - Generates unique tracking number
  /// - Saves request to Firestore with tracking number
  /// - Sends confirmation email to sender
  /// - Returns request ID for navigation/tracking
  Future<String> submitShippingRequest({
    required String requesterId,
    required ShippingRequestSimplified request,
    String? affiliateId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final trackingNumber = _generateTrackingNumber();
      final requestData = request.toFirestore();
      requestData['requesterId'] = requesterId;
      requestData['trackingNumber'] = trackingNumber;
      if (affiliateId != null) {
        requestData['affiliateId'] = affiliateId;
      }

      // Add to Firestore - ID is auto-generated
      final docRef =
          await FirebaseFirestore.instance.collection('shippingRequests').add({
        ...requestData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final requestId = docRef.id;

      // Send confirmation email
      try {
        await _emailService.sendShippingRequestConfirmation(
          toEmail: request.senderEmail,
          customerName: request.senderName,
          requestId: requestId,
          freightType: request.freightType,
          origin: request.departingLocation,
          destination: request.destinationLocation,
          itemDescription: request.itemDescription,
        );
      } catch (emailError) {
        // Log email error but don't fail the submission
        // Silently fail email - submission already succeeded
      }

      state = const AsyncValue.data(null);
      return requestId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Reset submission state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Riverpod provider for shipping submission notifier
final shippingSubmissionProvider =
    StateNotifierProvider<ShippingSubmissionNotifier, AsyncValue<void>>((ref) {
  return ShippingSubmissionNotifier();
});
