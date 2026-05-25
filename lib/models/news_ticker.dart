import 'package:cloud_firestore/cloud_firestore.dart';

/// News ticker item for announcements and updates feed
class NewsTicker {
  final String id;
  final String title;
  final String content;
  final int priority;
  final String status; // draft, published, archived
  final String? imageUrl;
  final Timestamp publishedAt;
  final Timestamp expiresAt;
  final Timestamp createdAt;
  final String createdBy;
  final Timestamp updatedAt;

  NewsTicker({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.status,
    this.imageUrl,
    required this.publishedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
  });

  /// Create from Firestore document snapshot
  factory NewsTicker.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return NewsTicker(
        id: doc.id,
        title: data['title'] ?? '',
        content: data['content'] ?? '',
        priority: data['priority'] ?? 0,
        status: data['status'] ?? 'draft',
        imageUrl: data['imageUrl'],
        publishedAt: data['publishedAt'] ?? Timestamp.now(),
        expiresAt: data['expiresAt'] ?? Timestamp.now(),
        createdAt: data['createdAt'] ?? Timestamp.now(),
        createdBy: data['createdBy'] ?? 'system',
        updatedAt: data['updatedAt'] ?? Timestamp.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'priority': priority,
      'status': status,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
    };
  }

  /// Get short preview for ticker display
  String getPreview({int maxLength = 50}) {
    if (title.length > maxLength) {
      return '${title.substring(0, maxLength)}...';
    }
    return title;
  }
}
