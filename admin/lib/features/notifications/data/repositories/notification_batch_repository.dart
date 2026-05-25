import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_batch.dart';

class NotificationBatchRepository {
  final FirebaseFirestore _firestore;

  static const String _batchesCollection = 'notification_batches';
  static const String _batchItemsCollection = 'notification_batch_items';

  NotificationBatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new batch
  Future<NotificationBatch> createBatch(NotificationBatch batch) async {
    final docRef = _firestore.collection(_batchesCollection).doc();
    final newBatch = batch.copyWith(id: docRef.id);

    await docRef.set(newBatch.toJson());
    return newBatch;
  }

  // Get batch by ID
  Future<NotificationBatch?> getBatchById(String id) async {
    final doc = await _firestore.collection(_batchesCollection).doc(id).get();
    if (!doc.exists) return null;

    return NotificationBatch.fromJson(doc.data()!);
  }

  // Get all batches
  Future<List<NotificationBatch>> getAllBatches() async {
    final query = await _firestore
        .collection(_batchesCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => NotificationBatch.fromJson(doc.data()))
        .toList();
  }

  // Get batches by status
  Future<List<NotificationBatch>> getBatchesByStatus(BatchStatus status) async {
    final query = await _firestore
        .collection(_batchesCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => NotificationBatch.fromJson(doc.data()))
        .toList();
  }

  // Get pending batches
  Future<List<NotificationBatch>> getPendingBatches() async {
    final query = await _firestore
        .collection(_batchesCollection)
        .where('status', whereIn: [
          BatchStatus.pending.name,
          BatchStatus.processing.name,
        ])
        .where('scheduledFor', isLessThanOrEqualTo: DateTime.now())
        .orderBy('scheduledFor')
        .get();

    return query.docs
        .map((doc) => NotificationBatch.fromJson(doc.data()))
        .toList();
  }

  // Update batch
  Future<void> updateBatch(NotificationBatch batch) async {
    await _firestore
        .collection(_batchesCollection)
        .doc(batch.id)
        .update(batch.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Start batch processing
  Future<void> startBatch(String batchId) async {
    final batch = await getBatchById(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    await updateBatch(
      batch.copyWith(
        status: BatchStatus.processing,
        startedAt: DateTime.now(),
      ),
    );
  }

  // Complete batch
  Future<void> completeBatch(String batchId) async {
    final batch = await getBatchById(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    await updateBatch(
      batch.copyWith(
        status: BatchStatus.completed,
        completedAt: DateTime.now(),
      ),
    );
  }

  // Fail batch
  Future<void> failBatch(String batchId, String errorMessage) async {
    final batch = await getBatchById(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    await updateBatch(
      batch.copyWith(
        status: BatchStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: errorMessage,
      ),
    );
  }

  // Cancel batch
  Future<void> cancelBatch(String batchId) async {
    final batch = await getBatchById(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    await updateBatch(
      batch.copyWith(
        status: BatchStatus.cancelled,
        completedAt: DateTime.now(),
      ),
    );
  }

  // Update batch progress
  Future<void> updateBatchProgress(
    String batchId,
    int sentCount,
    int deliveredCount,
    int failedCount,
  ) async {
    final batch = await getBatchById(batchId);
    if (batch == null) {
      throw Exception('Batch not found');
    }

    await updateBatch(
      batch.copyWith(
        sentCount: sentCount,
        deliveredCount: deliveredCount,
        failedCount: failedCount,
      ),
    );
  }

  // Delete batch
  Future<void> deleteBatch(String batchId) async {
    await _firestore.collection(_batchesCollection).doc(batchId).delete();
  }

  // Stream all batches
  Stream<List<NotificationBatch>> streamAllBatches() {
    return _firestore
        .collection(_batchesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationBatch.fromJson(doc.data()))
            .toList());
  }

  // Stream batches by status
  Stream<List<NotificationBatch>> streamBatchesByStatus(BatchStatus status) {
    return _firestore
        .collection(_batchesCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationBatch.fromJson(doc.data()))
            .toList());
  }

  // Batch Item Methods

  // Create batch item
  Future<BatchItem> createBatchItem(BatchItem item) async {
    final docRef = _firestore.collection(_batchItemsCollection).doc();
    final newItem = item.copyWith(id: docRef.id);

    await docRef.set(newItem.toJson());
    return newItem;
  }

  // Get batch items by batch ID
  Future<List<BatchItem>> getBatchItems(String batchId) async {
    final query = await _firestore
        .collection(_batchItemsCollection)
        .where('batchId', isEqualTo: batchId)
        .orderBy('createdAt')
        .get();

    return query.docs
        .map((doc) => BatchItem.fromJson(doc.data()))
        .toList();
  }

  // Get batch items by status
  Future<List<BatchItem>> getBatchItemsByStatus(
    String batchId,
    BatchItemStatus status,
  ) async {
    final query = await _firestore
        .collection(_batchItemsCollection)
        .where('batchId', isEqualTo: batchId)
        .where('status', isEqualTo: status.name)
        .get();

    return query.docs
        .map((doc) => BatchItem.fromJson(doc.data()))
        .toList();
  }

  // Get failed batch items
  Future<List<BatchItem>> getFailedBatchItems(String batchId) async {
    return await getBatchItemsByStatus(batchId, BatchItemStatus.failed);
  }

  // Update batch item
  Future<void> updateBatchItem(BatchItem item) async {
    await _firestore
        .collection(_batchItemsCollection)
        .doc(item.id)
        .update(item.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Mark batch item as sent
  Future<void> markItemAsSent(String itemId) async {
    final item = await getBatchItemById(itemId);
    if (item == null) {
      throw Exception('Batch item not found');
    }

    await updateBatchItem(
      item.copyWith(
        status: BatchItemStatus.sent,
        sentAt: DateTime.now(),
      ),
    );
  }

  // Mark batch item as delivered
  Future<void> markItemAsDelivered(String itemId) async {
    final item = await getBatchItemById(itemId);
    if (item == null) {
      throw Exception('Batch item not found');
    }

    await updateBatchItem(
      item.copyWith(
        status: BatchItemStatus.delivered,
        deliveredAt: DateTime.now(),
      ),
    );
  }

  // Mark batch item as failed
  Future<void> markItemAsFailed(String itemId, String errorMessage) async {
    final item = await getBatchItemById(itemId);
    if (item == null) {
      throw Exception('Batch item not found');
    }

    await updateBatchItem(
      item.copyWith(
        status: BatchItemStatus.failed,
        errorMessage: errorMessage,
      ),
    );
  }

  // Retry batch item
  Future<void> retryBatchItem(String itemId) async {
    final item = await getBatchItemById(itemId);
    if (item == null) {
      throw Exception('Batch item not found');
    }

    await updateBatchItem(
      item.copyWith(
        status: BatchItemStatus.retrying,
        retryCount: item.retryCount + 1,
      ),
    );
  }

  // Get batch item by ID
  Future<BatchItem?> getBatchItemById(String id) async {
    final doc = await _firestore.collection(_batchItemsCollection).doc(id).get();
    if (!doc.exists) return null;

    return BatchItem.fromJson(doc.data()!);
  }

  // Delete batch item
  Future<void> deleteBatchItem(String itemId) async {
    await _firestore.collection(_batchItemsCollection).doc(itemId).delete();
  }

  // Stream batch items
  Stream<List<BatchItem>> streamBatchItems(String batchId) {
    return _firestore
        .collection(_batchItemsCollection)
        .where('batchId', isEqualTo: batchId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BatchItem.fromJson(doc.data()))
            .toList());
  }

  // Retry failed items in a batch
  Future<void> retryFailedItems(String batchId) async {
    final failedItems = await getFailedBatchItems(batchId);

    for (final item in failedItems) {
      await retryBatchItem(item.id);
    }
  }

  // Get batch statistics
  Future<Map<String, dynamic>> getBatchStatistics() async {
    final all = await getAllBatches();

    final total = all.length;
    final pending = all.where((b) => b.status == BatchStatus.pending).length;
    final processing = all.where((b) => b.status == BatchStatus.processing).length;
    final completed = all.where((b) => b.status == BatchStatus.completed).length;
    final failed = all.where((b) => b.status == BatchStatus.failed).length;
    final cancelled = all.where((b) => b.status == BatchStatus.cancelled).length;

    final totalRecipients = all.fold<int>(0, (sum, b) => sum + b.totalRecipients);
    final totalSent = all.fold<int>(0, (sum, b) => sum + b.sentCount);
    final totalDelivered = all.fold<int>(0, (sum, b) => sum + b.deliveredCount);
    final totalFailed = all.fold<int>(0, (sum, b) => sum + b.failedCount);

    return {
      'total': total,
      'pending': pending,
      'processing': processing,
      'completed': completed,
      'failed': failed,
      'cancelled': cancelled,
      'totalRecipients': totalRecipients,
      'totalSent': totalSent,
      'totalDelivered': totalDelivered,
      'totalFailed': totalFailed,
      'overallDeliveryRate': totalSent > 0
          ? (totalDelivered / totalSent) * 100
          : 0,
      'overallFailureRate': totalSent > 0
          ? (totalFailed / totalSent) * 100
          : 0,
    };
  }
}