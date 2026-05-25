import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_template.dart';
import '../models/notification_type.dart';
import '../models/notification_category.dart';

class NotificationTemplateRepository {
  final FirebaseFirestore _firestore;

  NotificationTemplateRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'notification_templates';

  // ==================== CRUD OPERATIONS ====================

  /// Get all templates
  Future<List<NotificationTemplate>> getAll({
    TemplateStatus? status,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch templates: $e');
    }
  }

  /// Get templates as stream (real-time)
  Stream<List<NotificationTemplate>> getAllStream({
    TemplateStatus? status,
    int limit = 100,
  }) {
    var query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => _fromFirestore(doc)).toList(),
    );
  }

  /// Get template by ID
  Future<NotificationTemplate?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return _fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch template: $e');
    }
  }

  /// Get template by name
  Future<NotificationTemplate?> getByName(String name) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return _fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch template by name: $e');
    }
  }

  /// Get templates by type
  Future<List<NotificationTemplate>> getByType(
    NotificationType type, {
    TemplateStatus? status,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch templates by type: $e');
    }
  }

  /// Get templates by category
  Future<List<NotificationTemplate>> getByCategory(
    NotificationCategory category, {
    TemplateStatus? status,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.name)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch templates by category: $e');
    }
  }

  /// Get default templates
  Future<List<NotificationTemplate>> getDefaultTemplates() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isDefault', isEqualTo: true)
          .where('status', isEqualTo: TemplateStatus.active.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch default templates: $e');
    }
  }

  /// Create template
  Future<String> create(NotificationTemplate template) async {
    try {
      final docRef = _firestore.collection(_collection).doc(template.id);
      await docRef.set(template.toMap());
      return template.id;
    } catch (e) {
      throw Exception('Failed to create template: $e');
    }
  }

  /// Update template
  Future<void> update(NotificationTemplate template) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(template.id)
          .update(template.toMap()..['updatedAt'] = FieldValue.serverTimestamp());
    } catch (e) {
      throw Exception('Failed to update template: $e');
    }
  }

  /// Delete template
  Future<void> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete template: $e');
    }
  }

  /// Archive template
  Future<void> archive(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': TemplateStatus.archived.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to archive template: $e');
    }
  }

  /// Activate template
  Future<void> activate(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': TemplateStatus.active.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to activate template: $e');
    }
  }

  /// Mark template as used
  Future<void> markAsUsed(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'lastUsedAt': FieldValue.serverTimestamp(),
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to mark template as used: $e');
    }
  }

  /// Duplicate template
  Future<NotificationTemplate> duplicate(String id) async {
    try {
      final original = await getById(id);
      if (original == null) {
        throw Exception('Template not found');
      }

      final duplicate = NotificationTemplate(
        id: '${original.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
        name: '${original.name} (Copy)',
        description: original.description,
        type: original.type,
        category: original.category,
        title: original.title,
        message: original.message,
        actionUrl: original.actionUrl,
        variables: List.from(original.variables),
        status: TemplateStatus.draft,
        isDefault: false,
        version: 1,
        createdAt: DateTime.now(),
      );

      await create(duplicate);
      return duplicate;
    } catch (e) {
      throw Exception('Failed to duplicate template: $e');
    }
  }

  /// Search templates
  Future<List<NotificationTemplate>> search(
    String query, {
    int limit = 100,
  }) async {
    try {
      final allSnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2)
          .get();

      final lowerQuery = query.toLowerCase();
      return allSnapshot.docs
          .map((doc) => _fromFirestore(doc))
          .where((t) =>
              t.name.toLowerCase().contains(lowerQuery) ||
              t.description.toLowerCase().contains(lowerQuery) ||
              t.title.toLowerCase().contains(lowerQuery))
          .take(limit)
          .toList();
    } catch (e) {
      throw Exception('Failed to search templates: $e');
    }
  }

  // ==================== SEEDING ====================

  /// Seed default templates
  Future<void> seedDefaultTemplates() async {
    try {
      // Check if already seeded
      final existing = await _firestore
          .collection(_collection)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Default templates already seeded');
        return;
      }

      final defaultTemplates = DefaultNotificationTemplates.all();

      for (final template in defaultTemplates) {
        await _firestore.collection(_collection).doc(template.id).set(template.toMap());
      }

      print('✅ Seeded ${defaultTemplates.length} default templates');
    } catch (e) {
      print('Error seeding default templates: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  NotificationTemplate _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationTemplate.fromMap(data);
  }
}