import 'package:cloud_firestore/cloud_firestore.dart';

enum BannerType { info, alert, promotion, notice }

// Placement values must match what mobile app expects
enum BannerPlacement {
  home,
  top,
  sidebar,
  footer,
}

/// Banner model - for promotional/informational banners
class Banner {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl; // Route/URL when clicked
  final BannerType type;
  final BannerPlacement placement;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final int displayOrder;
  final int impressions;
  final int clicks;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;

  Banner({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    required this.type,
    required this.placement,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.displayOrder,
    required this.impressions,
    required this.clicks,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
  });

  bool get isVisible => active && DateTime.now().isBefore(endDate);
  double get clickThroughRate =>
      impressions == 0 ? 0 : (clicks / impressions) * 100;

  Banner copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? linkUrl,
    BannerType? type,
    BannerPlacement? placement,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    int? displayOrder,
    int? impressions,
    int? clicks,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      type: type ?? this.type,
      placement: placement ?? this.placement,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      displayOrder: displayOrder ?? this.displayOrder,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'type': type.name,
      'placement': placement.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'displayOrder': displayOrder,
      'impressions': impressions,
      'clicks': clicks,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Banner.fromMap(Map<String, dynamic> map, String docId) {
    return Banner(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      linkUrl: map['linkUrl'],
      type: BannerType.values.byName(map['type'] ?? 'info'),
      placement: BannerPlacement.values.byName(map['placement'] ?? 'home'),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      active: map['active'] ?? false,
      displayOrder: map['displayOrder'] ?? 0,
      impressions: map['impressions'] ?? 0,
      clicks: map['clicks'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? 'unknown',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Banner.empty() {
    final now = DateTime.now();
    return Banner(
      id: '',
      title: '',
      type: BannerType.info,
      placement: BannerPlacement.home,
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      active: false,
      displayOrder: 0,
      impressions: 0,
      clicks: 0,
      createdAt: now,
      createdBy: '',
      updatedAt: now,
    );
  }

  @override
  String toString() =>
      'Banner(id: $id, title: $title, type: $type, placement: $placement)';
}
