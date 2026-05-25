import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_segment.dart';

class UserSegmentRepository {
  final FirebaseFirestore _firestore;

  static const String _segmentsCollection = 'user_segments';
  static const String _membershipsCollection = 'segment_memberships';
  static const String _analyticsCollection = 'segment_analytics';

  UserSegmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new segment
  Future<UserSegment> createSegment(UserSegment segment) async {
    final docRef = _firestore.collection(_segmentsCollection).doc();
    final newSegment = segment.copyWith(id: docRef.id);

    await docRef.set(newSegment.toJson());
    return newSegment;
  }

  // Get segment by ID
  Future<UserSegment?> getSegmentById(String id) async {
    final doc = await _firestore.collection(_segmentsCollection).doc(id).get();
    if (!doc.exists) return null;

    return UserSegment.fromJson(doc.data()!);
  }

  // Get all segments
  Future<List<UserSegment>> getAllSegments() async {
    final query = await _firestore
        .collection(_segmentsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => UserSegment.fromJson(doc.data()))
        .toList();
  }

  // Get active segments
  Future<List<UserSegment>> getActiveSegments() async {
    final query = await _firestore
        .collection(_segmentsCollection)
        .where('status', isEqualTo: SegmentStatus.active.name)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => UserSegment.fromJson(doc.data()))
        .toList();
  }

  // Get segments by type
  Future<List<UserSegment>> getSegmentsByType(SegmentType type) async {
    final query = await _firestore
        .collection(_segmentsCollection)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => UserSegment.fromJson(doc.data()))
        .toList();
  }

  // Update segment
  Future<void> updateSegment(UserSegment segment) async {
    await _firestore
        .collection(_segmentsCollection)
        .doc(segment.id)
        .update(segment.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Activate segment
  Future<void> activateSegment(String segmentId) async {
    final segment = await getSegmentById(segmentId);
    if (segment == null) {
      throw Exception('Segment not found');
    }

    await updateSegment(
      segment.copyWith(status: SegmentStatus.active),
    );
  }

  // Deactivate segment
  Future<void> deactivateSegment(String segmentId) async {
    final segment = await getSegmentById(segmentId);
    if (segment == null) {
      throw Exception('Segment not found');
    }

    await updateSegment(
      segment.copyWith(status: SegmentStatus.inactive),
    );
  }

  // Archive segment
  Future<void> archiveSegment(String segmentId) async {
    final segment = await getSegmentById(segmentId);
    if (segment == null) {
      throw Exception('Segment not found');
    }

    await updateSegment(
      segment.copyWith(status: SegmentStatus.archived),
    );
  }

  // Delete segment
  Future<void> deleteSegment(String segmentId) async {
    await _firestore.collection(_segmentsCollection).doc(segmentId).delete();
  }

  // Stream all segments
  Stream<List<UserSegment>> streamAllSegments() {
    return _firestore
        .collection(_segmentsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserSegment.fromJson(doc.data()))
            .toList());
  }

  // Stream active segments
  Stream<List<UserSegment>> streamActiveSegments() {
    return _firestore
        .collection(_segmentsCollection)
        .where('status', isEqualTo: SegmentStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserSegment.fromJson(doc.data()))
            .toList());
  }

  // Segment Membership Methods

  // Add user to segment
  Future<SegmentMembership> addUserToSegment(
    String segmentId,
    String userId,
    String? addedBy,
    String? notes,
  ) async {
    final docRef = _firestore.collection(_membershipsCollection).doc();
    final membership = SegmentMembership(
      id: docRef.id,
      segmentId: segmentId,
      userId: userId,
      addedAt: DateTime.now(),
      addedBy: addedBy,
      notes: notes,
    );

    await docRef.set(membership.toJson());
    return membership;
  }

  // Remove user from segment
  Future<void> removeUserFromSegment(String segmentId, String userId) async {
    final query = await _firestore
        .collection(_membershipsCollection)
        .where('segmentId', isEqualTo: segmentId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Get users in segment
  Future<List<SegmentMembership>> getUsersInSegment(String segmentId) async {
    final query = await _firestore
        .collection(_membershipsCollection)
        .where('segmentId', isEqualTo: segmentId)
        .orderBy('addedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => SegmentMembership.fromJson(doc.data()))
        .toList();
  }

  // Get segments for user
  Future<List<SegmentMembership>> getSegmentsForUser(String userId) async {
    final query = await _firestore
        .collection(_membershipsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => SegmentMembership.fromJson(doc.data()))
        .toList();
  }

  // Check if user is in segment
  Future<bool> isUserInSegment(String segmentId, String userId) async {
    final query = await _firestore
        .collection(_membershipsCollection)
        .where('segmentId', isEqualTo: segmentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Stream users in segment
  Stream<List<SegmentMembership>> streamUsersInSegment(String segmentId) {
    return _firestore
        .collection(_membershipsCollection)
        .where('segmentId', isEqualTo: segmentId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SegmentMembership.fromJson(doc.data()))
            .toList());
  }

  // Calculate segment users (for dynamic segments)
  Future<List<String>> calculateSegmentUsers(
    UserSegment segment,
    List<Map<String, dynamic>> allUsers,
  ) async {
    final matchingUsers = <String>[];

    for (final user in allUsers) {
      final userId = user['id'] as String?;
      if (userId == null) continue;

      bool matches = true;
      for (final rule in segment.rules) {
        if (!rule.matches(user)) {
          matches = false;
          break;
        }
      }

      if (matches) {
        matchingUsers.add(userId);
      }
    }

    // Update segment with calculated count
    await updateSegment(
      segment.copyWith(
        userCount: matchingUsers.length,
        lastCalculatedAt: DateTime.now(),
      ),
    );

    return matchingUsers;
  }

  // Segment Analytics Methods

  // Create analytics record
  Future<SegmentAnalytics> createAnalytics(SegmentAnalytics analytics) async {
    final docRef = _firestore.collection(_analyticsCollection).doc();
    final newAnalytics = analytics.copyWith(segmentId: docRef.id);

    await docRef.set(newAnalytics.toJson());
    return newAnalytics;
  }

  // Get analytics for segment
  Future<SegmentAnalytics?> getAnalyticsForSegment(String segmentId) async {
    final query = await _firestore
        .collection(_analyticsCollection)
        .where('segmentId', isEqualTo: segmentId)
        .orderBy('calculatedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return SegmentAnalytics.fromJson(query.docs.first.data());
  }

  // Calculate analytics for segment
  Future<SegmentAnalytics> calculateSegmentAnalytics(String segmentId) async {
    final segment = await getSegmentById(segmentId);
    if (segment == null) {
      throw Exception('Segment not found');
    }

    final memberships = await getUsersInSegment(segmentId);

    // In a real implementation, you would fetch user data to determine
    // active/inactive status. For now, we'll use placeholder values.
    final activeUsers = memberships.length;
    final inactiveUsers = 0;

    final analytics = SegmentAnalytics(
      segmentId: segmentId,
      totalUsers: memberships.length,
      activeUsers: activeUsers,
      inactiveUsers: inactiveUsers,
      userDistribution: {
        'total': memberships.length,
        'active': activeUsers,
        'inactive': inactiveUsers,
      },
      calculatedAt: DateTime.now(),
    );

    return await createAnalytics(analytics);
  }

  // Get segment statistics
  Future<Map<String, dynamic>> getSegmentStatistics() async {
    final all = await getAllSegments();

    final total = all.length;
    final active = all.where((s) => s.status == SegmentStatus.active).length;
    final inactive = all.where((s) => s.status == SegmentStatus.inactive).length;
    final archived = all.where((s) => s.status == SegmentStatus.archived).length;

    final staticSegments = all.where((s) => s.type == SegmentType.static).length;
    final dynamicSegments = all.where((s) => s.type == SegmentType.dynamic).length;
    final customSegments = all.where((s) => s.type == SegmentType.custom).length;

    final totalUsers = all.fold<int>(0, (sum, s) => sum + s.userCount);

    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'archived': archived,
      'staticSegments': staticSegments,
      'dynamicSegments': dynamicSegments,
      'customSegments': customSegments,
      'totalUsers': totalUsers,
      'averageUsersPerSegment': total > 0 ? totalUsers / total : 0,
    };
  }
}