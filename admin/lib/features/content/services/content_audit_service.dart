import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Audit action types
enum AuditAction {
  create,
  update,
  delete,
  publish,
  unpublish,
  bulk_publish,
  bulk_unpublish,
  bulk_delete,
}

/// Entity types for audit logging
enum AuditEntityType {
  content_page,
  banner,
  faq,
  email_template,
}

/// Service for logging content audit trail
class ContentAuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection name for audit logs
  static const String _collectionName = 'content_audit_logs';

  /// Log an audit event
  Future<void> logEvent({
    required AuditAction action,
    required AuditEntityType entityType,
    required String entityId,
    String? entityName,
    Map<String, dynamic>? changes,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ Cannot log audit event: No authenticated user');
        return;
      }

      // Get user details from admin_users collection
      String? userRole;
      String? userDisplayName;
      try {
        final adminDoc = await _firestore.collection('admin_users').doc(user.uid).get();
        if (adminDoc.exists) {
          final data = adminDoc.data() as Map<String, dynamic>;
          userRole = data['role'] as String?;
          userDisplayName = data['displayName'] as String?;
        }
      } catch (e) {
        print('⚠️ Failed to fetch admin user details: $e');
      }

      final logEntry = {
        'action': action.name,
        'entityType': entityType.name,
        'entityId': entityId,
        'entityName': entityName,
        'changes': changes,
        'notes': notes,
        'userId': user.uid,
        'userEmail': user.email,
        'userDisplayName': userDisplayName,
        'userRole': userRole,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': '', // Can be populated from Cloud Functions
        'userAgent': '', // Can be populated from Cloud Functions
      };

      await _firestore.collection(_collectionName).add(logEntry);
      print('✅ Audit log created: ${action.name} on ${entityType.name} ($entityId)');
    } catch (e) {
      print('❌ Failed to create audit log: $e');
      // Don't throw - audit logging failures shouldn't break the main operation
    }
  }

  /// Get audit logs for a specific entity
  Future<List<Map<String, dynamic>>> getEntityLogs(
    AuditEntityType entityType,
    String entityId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('entityType', isEqualTo: entityType.name)
          .where('entityId', isEqualTo: entityId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Failed to fetch entity audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific user
  Future<List<Map<String, dynamic>>> getUserLogs(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Failed to fetch user audit logs: $e');
      return [];
    }
  }

  /// Get recent audit logs across all entities
  Future<List<Map<String, dynamic>>> getRecentLogs({
    int limit = 100,
    AuditEntityType? entityTypeFilter,
    AuditAction? actionFilter,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (entityTypeFilter != null) {
        query = query.where('entityType', isEqualTo: entityTypeFilter.name);
      }

      if (actionFilter != null) {
        query = query.where('action', isEqualTo: actionFilter.name);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Failed to fetch recent audit logs: $e');
      return [];
    }
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> getAuditStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      final logs = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Calculate statistics
      final actionCounts = <String, int>{};
      final entityTypeCounts = <String, int>{};
      final userCounts = <String, int>{};

      for (final log in logs) {
        final action = log['action'] as String? ?? 'unknown';
        final entityType = log['entityType'] as String? ?? 'unknown';
        final userId = log['userId'] as String? ?? 'unknown';

        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        entityTypeCounts[entityType] = (entityTypeCounts[entityType] ?? 0) + 1;
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      }

      return {
        'totalLogs': logs.length,
        'actionCounts': actionCounts,
        'entityTypeCounts': entityTypeCounts,
        'userCounts': userCounts,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };
    } catch (e) {
      print('❌ Failed to fetch audit statistics: $e');
      return {};
    }
  }

  /// Delete old audit logs (for cleanup)
  Future<void> deleteOldLogs({required DateTime beforeDate}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(beforeDate))
          .limit(500)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Deleted ${snapshot.docs.length} old audit logs');
    } catch (e) {
      print('❌ Failed to delete old audit logs: $e');
    }
  }
}