import 'package:cloud_firestore/cloud_firestore.dart';

/// App Banner for carousel and promotional content
class AppBanner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String position;
  final int displayOrder;
  final bool isActive;
  final Timestamp startDate;
  final Timestamp endDate;
  final int impressions;
  final int clicks;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String createdBy;
  final String updatedBy;

  AppBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.position,
    required this.displayOrder,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.impressions,
    required this.clicks,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  /// Create from Firestore document snapshot
  factory AppBanner.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return AppBanner(
        id: doc.id,
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        position: data['position'] ?? 'HOME_CAROUSEL',
        displayOrder: data['displayOrder'] ?? 0,
        isActive: data['isActive'] ?? false,
        startDate: data['startDate'] ?? Timestamp.now(),
        endDate: data['endDate'] ?? Timestamp.now(),
        impressions: data['impressions'] ?? 0,
        clicks: data['clicks'] ?? 0,
        createdAt: data['createdAt'] ?? Timestamp.now(),
        updatedAt: data['updatedAt'] ?? Timestamp.now(),
        createdBy: data['createdBy'] ?? 'system',
        updatedBy: data['updatedBy'] ?? 'system',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'position': position,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'startDate': startDate,
      'endDate': endDate,
      'impressions': impressions,
      'clicks': clicks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}
