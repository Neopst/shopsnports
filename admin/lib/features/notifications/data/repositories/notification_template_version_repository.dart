import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_template_version.dart';

class NotificationTemplateVersionRepository {
  final FirebaseFirestore _firestore;

  static const String _versionsCollection = 'notification_template_versions';
  static const String _abTestsCollection = 'notification_ab_tests';

  NotificationTemplateVersionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new template version
  Future<NotificationTemplateVersion> createVersion(
    NotificationTemplateVersion version,
  ) async {
    final docRef = _firestore.collection(_versionsCollection).doc();
    final newVersion = version.copyWith(id: docRef.id);

    await docRef.set(newVersion.toJson());
    return newVersion;
  }

  // Get version by ID
  Future<NotificationTemplateVersion?> getVersionById(String id) async {
    final doc = await _firestore.collection(_versionsCollection).doc(id).get();
    if (!doc.exists) return null;

    return NotificationTemplateVersion.fromJson(doc.data()!);
  }

  // Get all versions for a template
  Future<List<NotificationTemplateVersion>> getVersionsByTemplateId(
    String templateId,
  ) async {
    final query = await _firestore
        .collection(_versionsCollection)
        .where('templateId', isEqualTo: templateId)
        .orderBy('versionNumber', descending: true)
        .get();

    return query.docs
        .map((doc) => NotificationTemplateVersion.fromJson(doc.data()))
        .toList();
  }

  // Get published version for a template
  Future<NotificationTemplateVersion?> getPublishedVersion(
    String templateId,
  ) async {
    final query = await _firestore
        .collection(_versionsCollection)
        .where('templateId', isEqualTo: templateId)
        .where('status', isEqualTo: TemplateVersionStatus.published.name)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return NotificationTemplateVersion.fromJson(query.docs.first.data());
  }

  // Get latest version for a template
  Future<NotificationTemplateVersion?> getLatestVersion(
    String templateId,
  ) async {
    final query = await _firestore
        .collection(_versionsCollection)
        .where('templateId', isEqualTo: templateId)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return NotificationTemplateVersion.fromJson(query.docs.first.data());
  }

  // Update version
  Future<void> updateVersion(NotificationTemplateVersion version) async {
    await _firestore
        .collection(_versionsCollection)
        .doc(version.id)
        .update(version.toJson());
  }

  // Publish version
  Future<void> publishVersion(
    String versionId,
    String userId,
  ) async {
    final version = await getVersionById(versionId);
    if (version == null) {
      throw Exception('Version not found');
    }

    // Archive other published versions for this template
    final existingPublished = await _firestore
        .collection(_versionsCollection)
        .where('templateId', isEqualTo: version.templateId)
        .where('status', isEqualTo: TemplateVersionStatus.published.name)
        .get();

    for (final doc in existingPublished.docs) {
      await doc.reference.update({
        'status': TemplateVersionStatus.archived.name,
      });
    }

    // Publish this version
    await updateVersion(
      version.copyWith(
        status: TemplateVersionStatus.published,
        publishedAt: DateTime.now(),
        publishedBy: userId,
      ),
    );
  }

  // Archive version
  Future<void> archiveVersion(String versionId) async {
    final version = await getVersionById(versionId);
    if (version == null) {
      throw Exception('Version not found');
    }

    await updateVersion(
      version.copyWith(status: TemplateVersionStatus.archived),
    );
  }

  // Delete version
  Future<void> deleteVersion(String versionId) async {
    await _firestore.collection(_versionsCollection).doc(versionId).delete();
  }

  // Get next version number for a template
  Future<int> getNextVersionNumber(String templateId) async {
    final versions = await getVersionsByTemplateId(templateId);
    if (versions.isEmpty) return 1;

    return versions.first.versionNumber + 1;
  }

  // Stream versions for a template
  Stream<List<NotificationTemplateVersion>> streamVersionsByTemplateId(
    String templateId,
  ) {
    return _firestore
        .collection(_versionsCollection)
        .where('templateId', isEqualTo: templateId)
        .orderBy('versionNumber', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationTemplateVersion.fromJson(doc.data()))
            .toList());
  }

  // A/B Test Methods

  // Create A/B test
  Future<NotificationABTest> createABTest(NotificationABTest test) async {
    final docRef = _firestore.collection(_abTestsCollection).doc();
    final newTest = test.copyWith(id: docRef.id);

    await docRef.set(newTest.toJson());
    return newTest;
  }

  // Get A/B test by ID
  Future<NotificationABTest?> getABTestById(String id) async {
    final doc = await _firestore.collection(_abTestsCollection).doc(id).get();
    if (!doc.exists) return null;

    return NotificationABTest.fromJson(doc.data()!);
  }

  // Get all A/B tests
  Future<List<NotificationABTest>> getAllABTests() async {
    final query = await _firestore
        .collection(_abTestsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => NotificationABTest.fromJson(doc.data()))
        .toList();
  }

  // Get A/B tests by status
  Future<List<NotificationABTest>> getABTestsByStatus(
    ABTestStatus status,
  ) async {
    final query = await _firestore
        .collection(_abTestsCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => NotificationABTest.fromJson(doc.data()))
        .toList();
  }

  // Get A/B tests by template
  Future<List<NotificationABTest>> getABTestsByTemplate(
    String templateId,
  ) async {
    final query = await _firestore
        .collection(_abTestsCollection)
        .where('templateId', isEqualTo: templateId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => NotificationABTest.fromJson(doc.data()))
        .toList();
  }

  // Update A/B test
  Future<void> updateABTest(NotificationABTest test) async {
    await _firestore
        .collection(_abTestsCollection)
        .doc(test.id)
        .update(test.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Start A/B test
  Future<void> startABTest(String testId) async {
    final test = await getABTestById(testId);
    if (test == null) {
      throw Exception('A/B test not found');
    }

    await updateABTest(
      test.copyWith(
        status: ABTestStatus.active,
        startDate: DateTime.now(),
      ),
    );
  }

  // Pause A/B test
  Future<void> pauseABTest(String testId) async {
    final test = await getABTestById(testId);
    if (test == null) {
      throw Exception('A/B test not found');
    }

    await updateABTest(
      test.copyWith(
        status: ABTestStatus.paused,
        endDate: DateTime.now(),
      ),
    );
  }

  // Complete A/B test
  Future<void> completeABTest(
    String testId,
    String? winningVariantId,
  ) async {
    final test = await getABTestById(testId);
    if (test == null) {
      throw Exception('A/B test not found');
    }

    await updateABTest(
      test.copyWith(
        status: ABTestStatus.completed,
        endDate: DateTime.now(),
        winningVariantId: winningVariantId,
      ),
    );
  }

  // Cancel A/B test
  Future<void> cancelABTest(String testId) async {
    final test = await getABTestById(testId);
    if (test == null) {
      throw Exception('A/B test not found');
    }

    await updateABTest(
      test.copyWith(
        status: ABTestStatus.cancelled,
        endDate: DateTime.now(),
      ),
    );
  }

  // Update A/B test metrics
  Future<void> updateABTestMetrics(
    String testId,
    String variantId,
    ABTestMetrics metrics,
  ) async {
    final test = await getABTestById(testId);
    if (test == null) {
      throw Exception('A/B test not found');
    }

    final updatedVariants = test.variants.map((variant) {
      if (variant.id == variantId) {
        return ABTestVariant(
          id: variant.id,
          name: variant.name,
          versionId: variant.versionId,
          allocation: variant.allocation,
          metrics: metrics,
        );
      }
      return variant;
    }).toList();

    // Update overall metrics
    final updatedMetrics = Map<String, ABTestMetrics>.from(test.metrics);
    updatedMetrics[variantId] = metrics;

    await updateABTest(
      test.copyWith(
        variants: updatedVariants,
        metrics: updatedMetrics,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Delete A/B test
  Future<void> deleteABTest(String testId) async {
    await _firestore.collection(_abTestsCollection).doc(testId).delete();
  }

  // Stream all A/B tests
  Stream<List<NotificationABTest>> streamAllABTests() {
    return _firestore
        .collection(_abTestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationABTest.fromJson(doc.data()))
            .toList());
  }

  // Stream A/B tests by status
  Stream<List<NotificationABTest>> streamABTestsByStatus(
    ABTestStatus status,
  ) {
    return _firestore
        .collection(_abTestsCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationABTest.fromJson(doc.data()))
            .toList());
  }

  // Get A/B test statistics
  Future<Map<String, dynamic>> getABTestStatistics() async {
    final all = await getAllABTests();

    final total = all.length;
    final active = all.where((t) => t.status == ABTestStatus.active).length;
    final completed = all.where((t) => t.status == ABTestStatus.completed).length;
    final draft = all.where((t) => t.status == ABTestStatus.draft).length;
    final paused = all.where((t) => t.status == ABTestStatus.paused).length;

    final totalSent = all.fold<int>(0, (sum, t) => sum + t.sentCount);
    final totalRecipients = all.fold<int>(0, (sum, t) => sum + t.totalRecipients);

    return {
      'total': total,
      'active': active,
      'completed': completed,
      'draft': draft,
      'paused': paused,
      'totalSent': totalSent,
      'totalRecipients': totalRecipients,
      'completionRate': totalRecipients > 0
          ? (totalSent / totalRecipients) * 100
          : 0,
    };
  }
}