import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_export.dart';

/// Repository for managing invoice exports
class InvoiceExportRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'invoice_exports';

  InvoiceExportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new invoice export
  Future<InvoiceExport> create(InvoiceExport export) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newExport = export.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newExport.toMap());
      return newExport;
    } catch (e) {
      throw Exception('Failed to create export: $e');
    }
  }

  /// Get an export by ID
  Future<InvoiceExport?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return InvoiceExport.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get export: $e');
    }
  }

  /// Get all exports with pagination
  Future<List<InvoiceExport>> getAll({
    int limit = 50,
    InvoiceExport? lastExport,
    ExportStatus? status,
    ExportFormat? format,
    String? createdBy,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (format != null) {
        query = query.where('format', isEqualTo: format.name);
      }

      if (createdBy != null) {
        query = query.where('createdBy', isEqualTo: createdBy);
      }

      query = query.orderBy('createdAt', descending: true);

      if (lastExport != null) {
        query = query.startAfter([lastExport.createdAt]);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => InvoiceExport.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exports: $e');
    }
  }

  /// Get exports by date range
  Future<List<InvoiceExport>> getByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceExport.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exports by date range: $e');
    }
  }

  /// Get exports by user
  Future<List<InvoiceExport>> getByUser(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceExport.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get exports by user: $e');
    }
  }

  /// Update an export
  Future<InvoiceExport> update(InvoiceExport export) async {
    try {
      final updatedExport = export.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(export.id)
          .update(updatedExport.toMap());

      return updatedExport;
    } catch (e) {
      throw Exception('Failed to update export: $e');
    }
  }

  /// Mark export as processing
  Future<InvoiceExport> markAsProcessing(String exportId) async {
    try {
      final export = await getById(exportId);
      if (export == null) {
        throw Exception('Export not found');
      }

      final updated = export.copyWith(
        status: ExportStatus.processing,
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to mark export as processing: $e');
    }
  }

  /// Mark export as completed
  Future<InvoiceExport> markAsCompleted(
    String exportId,
    String filePath,
    int fileSize,
    String downloadUrl,
  ) async {
    try {
      final export = await getById(exportId);
      if (export == null) {
        throw Exception('Export not found');
      }

      final updated = export.copyWith(
        status: ExportStatus.completed,
        filePath: filePath,
        fileSize: fileSize,
        downloadUrl: downloadUrl,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to mark export as completed: $e');
    }
  }

  /// Mark export as failed
  Future<InvoiceExport> markAsFailed(
    String exportId,
    String errorMessage,
  ) async {
    try {
      final export = await getById(exportId);
      if (export == null) {
        throw Exception('Export not found');
      }

      final updated = export.copyWith(
        status: ExportStatus.failed,
        errorMessage: errorMessage,
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to mark export as failed: $e');
    }
  }

  /// Cancel an export
  Future<InvoiceExport> cancel(String exportId) async {
    try {
      final export = await getById(exportId);
      if (export == null) {
        throw Exception('Export not found');
      }

      if (export.status != ExportStatus.pending &&
          export.status != ExportStatus.processing) {
        throw Exception('Export cannot be cancelled');
      }

      final updated = export.copyWith(
        status: ExportStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      return await update(updated);
    } catch (e) {
      throw Exception('Failed to cancel export: $e');
    }
  }

  /// Delete an export
  Future<void> delete(String exportId) async {
    try {
      await _firestore.collection(_collection).doc(exportId).delete();
    } catch (e) {
      throw Exception('Failed to delete export: $e');
    }
  }

  /// Get export statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final stats = <String, dynamic>{
        'total': snapshot.docs.length,
        'pending': 0,
        'processing': 0,
        'completed': 0,
        'failed': 0,
        'cancelled': 0,
        'formats': <String, int>{},
        'totalInvoicesExported': 0,
        'totalFileSize': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        stats[status] = (stats[status] as int) + 1;

        final format = data['format'] as String;
        stats['formats'][format] = (stats['formats'][format] as int? ?? 0) + 1;

        final totalInvoices = data['totalInvoices'] as int? ?? 0;
        stats['totalInvoicesExported'] =
            (stats['totalInvoicesExported'] as int) + totalInvoices;

        final fileSize = data['fileSize'] as int? ?? 0;
        stats['totalFileSize'] = (stats['totalFileSize'] as int) + fileSize;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Stream all exports
  Stream<List<InvoiceExport>> streamAll({
    int limit = 50,
    ExportStatus? status,
  }) {
    Query query = _firestore.collection(_collection);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => InvoiceExport.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Stream export by ID
  Stream<InvoiceExport?> streamById(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? InvoiceExport.fromMap(doc.data()!) : null);
  }

  /// Get recent exports (last 7 days)
  Future<List<InvoiceExport>> getRecentExports({int limit = 10}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => InvoiceExport.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent exports: $e');
    }
  }

  /// Clean up old exports (older than 30 days)
  Future<int> cleanupOldExports() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to cleanup old exports: $e');
    }
  }
}