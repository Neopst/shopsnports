import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_reminder.dart';

/// Repository for managing invoice reminders
class InvoiceReminderRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'invoice_reminders';

  InvoiceReminderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new invoice reminder
  Future<InvoiceReminder> create(InvoiceReminder reminder) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newReminder = reminder.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newReminder.toMap());
      return newReminder;
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  /// Get a reminder by ID
  Future<InvoiceReminder?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return InvoiceReminder.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get reminder: $e');
    }
  }

  /// Get all reminders for an invoice
  Future<List<InvoiceReminder>> getByInvoiceId(String invoiceId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('invoiceId', isEqualTo: invoiceId)
          .orderBy('scheduledDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reminders for invoice: $e');
    }
  }

  /// Get all reminders for a customer
  Future<List<InvoiceReminder>> getByCustomerId(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('scheduledDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reminders for customer: $e');
    }
  }

  /// Get all pending reminders
  Future<List<InvoiceReminder>> getPendingReminders() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .where('scheduledDate', isLessThanOrEqualTo: DateTime.now())
          .orderBy('scheduledDate')
          .get();

      return snapshot.docs
          .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending reminders: $e');
    }
  }

  /// Get all overdue reminders
  Future<List<InvoiceReminder>> getOverdueReminders() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .where('scheduledDate', isLessThan: DateTime.now())
          .orderBy('scheduledDate')
          .get();

      return snapshot.docs
          .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get overdue reminders: $e');
    }
  }

  /// Get all failed reminders
  Future<List<InvoiceReminder>> getFailedReminders() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'failed')
          .orderBy('lastAttemptAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get failed reminders: $e');
    }
  }

  /// Get all reminders with pagination
  Future<List<InvoiceReminder>> getAll({
    int limit = 50,
    InvoiceReminder? lastReminder,
    ReminderStatus? status,
    ReminderType? type,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.orderBy('scheduledDate', descending: true);

      if (lastReminder != null) {
        query = query.startAfter([lastReminder.scheduledDate]);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reminders: $e');
    }
  }

  /// Update a reminder
  Future<InvoiceReminder> update(InvoiceReminder reminder) async {
    try {
      final updatedReminder = reminder.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(reminder.id)
          .update(updatedReminder.toMap());

      return updatedReminder;
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  /// Mark reminder as sent
  Future<InvoiceReminder> markAsSent(String reminderId) async {
    try {
      final reminder = await getById(reminderId);
      if (reminder == null) {
        throw Exception('Reminder not found');
      }

      final updated = reminder.copyWith(
        status: ReminderStatus.sent,
        sentDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to mark reminder as sent: $e');
    }
  }

  /// Mark reminder as failed
  Future<InvoiceReminder> markAsFailed(
    String reminderId,
    String errorMessage,
  ) async {
    try {
      final reminder = await getById(reminderId);
      if (reminder == null) {
        throw Exception('Reminder not found');
      }

      final updated = reminder.copyWith(
        status: ReminderStatus.failed,
        errorMessage: errorMessage,
        attemptCount: reminder.attemptCount + 1,
        lastAttemptAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to mark reminder as failed: $e');
    }
  }

  /// Cancel a reminder
  Future<InvoiceReminder> cancel(String reminderId) async {
    try {
      final reminder = await getById(reminderId);
      if (reminder == null) {
        throw Exception('Reminder not found');
      }

      final updated = reminder.copyWith(
        status: ReminderStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to cancel reminder: $e');
    }
  }

  /// Retry a failed reminder
  Future<InvoiceReminder> retry(String reminderId) async {
    try {
      final reminder = await getById(reminderId);
      if (reminder == null) {
        throw Exception('Reminder not found');
      }

      if (!reminder.canRetry) {
        throw Exception('Reminder cannot be retried');
      }

      final updated = reminder.copyWith(
        status: ReminderStatus.pending,
        scheduledDate: DateTime.now(),
        errorMessage: null,
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to retry reminder: $e');
    }
  }

  /// Delete a reminder
  Future<void> delete(String reminderId) async {
    try {
      await _firestore.collection(_collection).doc(reminderId).delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  /// Get reminder statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'pending': 0,
        'sent': 0,
        'failed': 0,
        'cancelled': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Stream reminders for an invoice
  Stream<List<InvoiceReminder>> streamByInvoiceId(String invoiceId) {
    return _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream pending reminders
  Stream<List<InvoiceReminder>> streamPendingReminders() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .where('scheduledDate', isLessThanOrEqualTo: DateTime.now())
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceReminder.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}