import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_ab_test.dart';

class NotificationABTestRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'notification_ab_tests';

  NotificationABTestRepository(this._firestore);

  // Get all A/B tests
  Stream<List<NotificationABTest>> getAllABTests() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationABTest.fromFirestore(doc))
            .toList());
  }

  // Get A/B test by ID
  Future<NotificationABTest?> getABTestById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return NotificationABTest.fromFirestore(doc);
  }

  // Get A/B tests by status
  Stream<List<NotificationABTest>> getABTestsByStatus(ABTestStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationABTest.fromFirestore(doc))
            .toList());
  }

  // Get A/B tests by template
  Stream<List<NotificationABTest>> getABTestsByTemplate(String templateId) {
    return _firestore
        .collection(_collection)
        .where('templateId', isEqualTo: templateId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationABTest.fromFirestore(doc))
            .toList());
  }

  // Create new A/B test
  Future<NotificationABTest> createABTest(NotificationABTest abTest) async {
    final docRef = await _firestore.collection(_collection).add(abTest.toFirestore());
    final doc = await docRef.get();
    return NotificationABTest.fromFirestore(doc);
  }

  // Update A/B test
  Future<void> updateABTest(NotificationABTest abTest) async {
    await _firestore
        .collection(_collection)
        .doc(abTest.id)
        .update(abTest.toFirestore());
  }

  // Update A/B test status
  Future<void> updateABTestStatus(String id, ABTestStatus status) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': status.name,
      if (status == ABTestStatus.running) 'startedAt': FieldValue.serverTimestamp(),
      if (status == ABTestStatus.completed || status == ABTestStatus.cancelled)
        'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update variant metrics
  Future<void> updateVariantMetrics(
    String abTestId,
    String variantId, {
    int? sentCount,
    int? deliveredCount,
    int? openedCount,
    int? clickedCount,
  }) async {
    final updates = <String, dynamic>{};
    if (sentCount != null) updates['sentCount'] = sentCount;
    if (deliveredCount != null) updates['deliveredCount'] = deliveredCount;
    if (openedCount != null) updates['openedCount'] = openedCount;
    if (clickedCount != null) updates['clickedCount'] = clickedCount;

    if (updates.isEmpty) return;

    await _firestore
        .collection(_collection)
        .doc(abTestId)
        .update({
          'variants': FieldValue.arrayUnion([
            {'id': variantId, ...updates}
          ])
        });
  }

  // Calculate and update results
  Future<void> calculateResults(String abTestId) async {
    final abTest = await getABTestById(abTestId);
    if (abTest == null || abTest.variants.isEmpty) return;

    int totalSent = 0;
    int totalDelivered = 0;
    int totalOpened = 0;
    int totalClicked = 0;

    String winningVariantId = abTest.variants.first.id;
    double bestOpenRate = 0;

    for (final variant in abTest.variants) {
      totalSent += variant.sentCount;
      totalDelivered += variant.deliveredCount;
      totalOpened += variant.openedCount;
      totalClicked += variant.clickedCount;

      if (variant.openRate > bestOpenRate) {
        bestOpenRate = variant.openRate;
        winningVariantId = variant.id;
      }
    }

    final overallOpenRate = totalSent > 0 ? totalOpened / totalSent : 0.0;
    final overallClickRate = totalOpened > 0 ? totalClicked / totalOpened : 0.0;
    final overallConversionRate = totalDelivered > 0 ? totalClicked / totalDelivered : 0.0;

    final results = ABTestResults(
      totalSent: totalSent,
      totalDelivered: totalDelivered,
      totalOpened: totalOpened,
      totalClicked: totalClicked,
      overallOpenRate: overallOpenRate,
      overallClickRate: overallClickRate,
      overallConversionRate: overallConversionRate,
      winningVariantId: winningVariantId,
      statisticalSignificance: _calculateSignificance(abTest.variants),
      calculatedAt: DateTime.now(),
    );

    await _firestore.collection(_collection).doc(abTestId).update({
      'results': results.toJson(),
    });
  }

  // Set winner
  Future<void> setWinner(
    String abTestId,
    String variantId,
    String reason,
    String selectedBy,
  ) async {
    final abTest = await getABTestById(abTestId);
    if (abTest == null) return;

    final variant = abTest.variants.firstWhere((v) => v.id == variantId);
    final controlVariant = abTest.variants.firstWhere((v) => v.isControl);

    final improvementPercentage = controlVariant.openRate > 0
        ? ((variant.openRate - controlVariant.openRate) / controlVariant.openRate) * 100
        : 0.0;

    final winner = ABTestWinner(
      variantId: variantId,
      variantName: variant.name,
      reason: reason,
      improvementPercentage: improvementPercentage,
      selectedAt: DateTime.now(),
      selectedBy: selectedBy,
    );

    await _firestore.collection(_collection).doc(abTestId).update({
      'winner': winner.toJson(),
      'status': ABTestStatus.completed.name,
      'endedAt': FieldValue.serverTimestamp(),
      'endedBy': selectedBy,
    });
  }

  // Delete A/B test
  Future<void> deleteABTest(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Get A/B test statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();
    final tests = snapshot.docs
        .map((doc) => NotificationABTest.fromFirestore(doc))
        .toList();

    final totalTests = tests.length;
    final completedTests = tests.where((t) => t.status == ABTestStatus.completed).length;
    final runningTests = tests.where((t) => t.status == ABTestStatus.running).length;
    final draftTests = tests.where((t) => t.status == ABTestStatus.draft).length;

    double averageOpenRate = 0;
    double averageClickRate = 0;

    final completedWithResults = tests.where((t) => t.results != null).toList();
    if (completedWithResults.isNotEmpty) {
      averageOpenRate = completedWithResults
              .map((t) => t.results!.overallOpenRate)
              .reduce((a, b) => a + b) /
          completedWithResults.length;
      averageClickRate = completedWithResults
              .map((t) => t.results!.overallClickRate)
              .reduce((a, b) => a + b) /
          completedWithResults.length;
    }

    return {
      'totalTests': totalTests,
      'completedTests': completedTests,
      'runningTests': runningTests,
      'draftTests': draftTests,
      'averageOpenRate': averageOpenRate,
      'averageClickRate': averageClickRate,
    };
  }

  // Calculate statistical significance (simplified chi-square test)
  double _calculateSignificance(List<ABTestVariant> variants) {
    if (variants.length < 2) return 0.0;

    // Simplified calculation - in production, use proper statistical library
    final control = variants.firstWhere((v) => v.isControl, orElse: () => variants.first);
    final treatment = variants.firstWhere((v) => !v.isControl, orElse: () => variants.last);

    if (control.sentCount == 0 || treatment.sentCount == 0) return 0.0;

    final controlRate = control.openRate;
    final treatmentRate = treatment.openRate;

    final difference = (treatmentRate - controlRate).abs();
    final pooledRate = (control.openedCount + treatment.openedCount) /
        (control.sentCount + treatment.sentCount);

    final standardError = sqrt(
      pooledRate * (1 - pooledRate) * (1 / control.sentCount + 1 / treatment.sentCount),
    );

    if (standardError == 0) return 0.0;

    final zScore = difference / standardError;
    // Convert z-score to confidence level (simplified)
    return (zScore * 10).clamp(0, 100);
  }
}

double sqrt(double value) {
  return math.sqrt(value);
}