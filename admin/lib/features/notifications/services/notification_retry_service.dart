import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository_firestore.dart';

/// Service for handling notification retry logic with exponential backoff
class NotificationRetryService {
  final NotificationRepositoryFirestore _repository;
  final FirebaseFirestore _firestore;

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialBackoff = Duration(seconds: 5);
  static const double backoffMultiplier = 2.0;
  static const Duration maxBackoff = Duration(minutes: 5);

  // Active retry timers
  final Map<String, Timer> _retryTimers = {};

  NotificationRetryService({
    required NotificationRepositoryFirestore repository,
    FirebaseFirestore? firestore,
  })  : _repository = repository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate exponential backoff delay for retry attempt
  Duration calculateBackoff(int retryCount) {
    final exponentialDelay = initialBackoff *
        pow(backoffMultiplier, retryCount).toInt();
    return exponentialDelay > maxBackoff ? maxBackoff : exponentialDelay;
  }

  /// Schedule a retry for a failed notification
  void scheduleRetry(String notificationId) async {
    // Cancel any existing retry for this notification
    cancelRetry(notificationId);

    // Get the notification to check retry count
    final notification = await _repository.getNotificationById(notificationId);
    if (notification == null) {
      print('Notification not found: $notificationId');
      return;
    }

    if (notification.retryCount >= maxRetries) {
      print('Max retries exceeded for notification: $notificationId');
      return;
    }

    // Calculate backoff delay
    final delay = calculateBackoff(notification.retryCount);

    print('Scheduling retry for $notificationId in ${delay.inSeconds}s');

    // Schedule retry
    _retryTimers[notificationId] = Timer(delay, () async {
      await _executeRetry(notificationId);
    });
  }

  /// Execute the retry for a notification
  Future<void> _executeRetry(String notificationId) async {
    try {
      // Get the notification
      final notification = await _repository.getNotificationById(notificationId);
      if (notification == null) {
        print('Notification not found for retry: $notificationId');
        return;
      }

      // Update retry count
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'retryCount': FieldValue.increment(1),
        'lastRetryAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('Retry executed for notification: $notificationId');

      // Remove timer
      _retryTimers.remove(notificationId);
    } catch (e) {
      print('Error executing retry for $notificationId: $e');

      // Mark as permanently failed if this was the last retry
      final notification = await _repository.getNotificationById(notificationId);
      if (notification != null && notification.retryCount >= maxRetries - 1) {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .update({
          'status': 'permanently_failed',
          'errorMessage': 'Max retries exceeded: $e',
        });
      }
    }
  }

  /// Cancel a scheduled retry
  void cancelRetry(String notificationId) {
    final timer = _retryTimers.remove(notificationId);
    if (timer != null) {
      timer.cancel();
      print('Cancelled retry for notification: $notificationId');
    }
  }

  /// Manually retry a failed notification immediately
  Future<bool> manualRetry(String notificationId) async {
    try {
      // Cancel any scheduled retry
      cancelRetry(notificationId);

      // Get the notification
      final notification = await _repository.getNotificationById(notificationId);
      if (notification == null) {
        print('Notification not found: $notificationId');
        return false;
      }

      // Check if retry is allowed
      if (notification.retryCount >= maxRetries) {
        print('Max retries exceeded for notification: $notificationId');
        return false;
      }

      // Reset status to pending and increment retry count
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': 'pending',
        'retryCount': FieldValue.increment(1),
        'lastRetryAt': FieldValue.serverTimestamp(),
        'errorMessage': null,
      });

      print('Manual retry initiated for notification: $notificationId');
      return true;
    } catch (e) {
      print('Error in manual retry for $notificationId: $e');
      return false;
    }
  }

  /// Get all failed notifications that can be retried
  Future<List<Notification>> getRetryableNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('status', isEqualTo: 'failed')
          .where('retryCount', isLessThan: maxRetries)
          .get();

      return snapshot.docs
          .map((doc) => Notification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching retryable notifications: $e');
      return [];
    }
  }

  /// Get retry statistics for a notification
  Future<Map<String, dynamic>> getRetryStats(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!doc.exists) {
        return {};
      }

      final data = doc.data() as Map<String, dynamic>;
      final retryCount = data['retryCount'] ?? 0;
      final lastRetryAt = data['lastRetryAt'] as Timestamp?;

      return {
        'retryCount': retryCount,
        'maxRetries': maxRetries,
        'canRetry': retryCount < maxRetries,
        'lastRetryAt': lastRetryAt?.toDate(),
        'nextRetryIn': retryCount < maxRetries
            ? calculateBackoff(retryCount)
            : null,
      };
    } catch (e) {
      print('Error getting retry stats: $e');
      return {};
    }
  }

  /// Clean up all active retry timers
  void dispose() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
  }

  /// Get count of active retry timers
  int get activeRetryCount => _retryTimers.length;
}