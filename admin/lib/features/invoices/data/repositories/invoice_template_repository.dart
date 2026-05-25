import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_template.dart';

class InvoiceTemplateRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'invoice_templates';

  InvoiceTemplateRepository(this._firestore);

  // Get all templates
  Stream<List<InvoiceTemplate>> getAllTemplates() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceTemplate.fromFirestore(doc))
            .toList());
  }

  // Get active templates only
  Stream<List<InvoiceTemplate>> getActiveTemplates() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceTemplate.fromFirestore(doc))
            .toList());
  }

  // Get default template
  Future<InvoiceTemplate?> getDefaultTemplate() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InvoiceTemplate.fromFirestore(snapshot.docs.first);
  }

  // Get template by ID
  Future<InvoiceTemplate?> getTemplateById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceTemplate.fromFirestore(doc);
  }

  // Create new template
  Future<InvoiceTemplate> createTemplate(InvoiceTemplate template) async {
    // If this is set as default, unset other defaults
    if (template.isDefault) {
      await _clearDefaultTemplate();
    }

    final docRef = await _firestore.collection(_collection).add(template.toFirestore());
    final doc = await docRef.get();
    return InvoiceTemplate.fromFirestore(doc);
  }

  // Update template
  Future<void> updateTemplate(InvoiceTemplate template) async {
    // If this is set as default, unset other defaults
    if (template.isDefault) {
      await _clearDefaultTemplate(exceptId: template.id);
    }

    await _firestore
        .collection(_collection)
        .doc(template.id)
        .update(template.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  // Set as default
  Future<void> setAsDefault(String id) async {
    await _clearDefaultTemplate();
    await _firestore.collection(_collection).doc(id).update({
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Toggle active status
  Future<void> toggleActive(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete template
  Future<void> deleteTemplate(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Duplicate template
  Future<InvoiceTemplate> duplicateTemplate(String id) async {
    final original = await getTemplateById(id);
    if (original == null) throw Exception('Template not found');

    final duplicate = original.copyWith(
      id: '',
      name: '${original.name} (Copy)',
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: null,
      usageCount: 0,
    );

    return createTemplate(duplicate);
  }

  // Increment usage count
  Future<void> incrementUsage(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  // Get template statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();
    final templates = snapshot.docs
        .map((doc) => InvoiceTemplate.fromFirestore(doc))
        .toList();

    final totalTemplates = templates.length;
    final activeTemplates = templates.where((t) => t.isActive).length;
    final defaultTemplate = templates.firstWhere(
      (t) => t.isDefault,
      orElse: () => templates.first,
    );
    final totalUsage = templates.fold<int>(0, (sum, t) => sum + t.usageCount);

    final layoutCounts = <TemplateLayout, int>{};
    for (final template in templates) {
      layoutCounts[template.layout] = (layoutCounts[template.layout] ?? 0) + 1;
    }

    return {
      'totalTemplates': totalTemplates,
      'activeTemplates': activeTemplates,
      'defaultTemplateId': defaultTemplate.id,
      'totalUsage': totalUsage,
      'layoutCounts': layoutCounts,
    };
  }

  // Clear default template (except specified ID)
  Future<void> _clearDefaultTemplate({String? exceptId}) async {
    final query = _firestore.collection(_collection).where('isDefault', isEqualTo: true);
    if (exceptId != null) {
      query.where('id', isNotEqualTo: exceptId);
    }

    final snapshot = await query.get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }
}