import 'package:cloud_firestore/cloud_firestore.dart';

/// Banner model
class Banner {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final String placement;
  final int displayOrder;
  final bool active;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  Banner({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
    this.placement = 'home',
    this.displayOrder = 0,
    this.active = true,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory Banner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Banner(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String? ?? data['image_url'] as String? ?? '',
      linkUrl: data['linkUrl'] as String? ?? data['link_url'] as String?,
      placement: data['placement'] as String? ?? 'home',
      displayOrder: data['displayOrder'] as int? ?? data['display_order'] as int? ?? 0,
      active: data['active'] as bool? ?? true,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  bool get isValid {
    final now = DateTime.now();
    if (!active) return false;
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  String? get subtitle => description;
}

/// Banners Service - Firestore-based
///
/// Firebase is the single source of truth for all banner data
class BannersService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final BannersService _instance = BannersService._();
  factory BannersService() => _instance;
  BannersService._();

  /// Get all banners (admin use)
  Future<List<Banner>> getAllBanners() async {
    try {
      final snapshot = await _db
          .collection('banners')
          .orderBy('displayOrder')
          .get();

      return snapshot.docs.map((doc) => Banner.fromFirestore(doc)).toList();
    } catch (e) {
      // Silently fail - empty list returned
      return [];
    }
  }

  /// Get active banners for display
  Future<List<Banner>> getActiveBanners({String placement = 'home'}) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());

      final snapshot = await _db
          .collection('banners')
          .where('placement', isEqualTo: placement)
          .where('active', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => Banner.fromFirestore(doc))
          .where((banner) => banner.isValid)
          .toList();
    } catch (e) {
      // Silently fail - empty list returned
      return [];
    }
  }

  /// Stream of active banners (real-time updates)
  Stream<List<Banner>> watchActiveBanners({String placement = 'home'}) {
    return _db
        .collection('banners')
        .where('placement', isEqualTo: placement)
        .where('active', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Banner.fromFirestore(doc))
          .where((banner) => banner.isValid)
          .toList();
    });
  }

  /// Get single banner by ID
  Future<Banner?> getBannerById(String id) async {
    try {
      final doc = await _db.collection('banners').doc(id).get();
      if (doc.exists) {
        return Banner.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Silently fail - return null
      return null;
    }
  }
}