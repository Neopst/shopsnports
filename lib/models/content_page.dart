import 'package:cloud_firestore/cloud_firestore.dart';

/// Content page for legal docs, FAQ, help, privacy, etc.
class ContentPage {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String content;
  final String contentType; // TEXT, HTML, MARKDOWN
  final List<String> tags;
  final String status; // draft, published, archived
  final Timestamp publishedAt;
  final String publishedBy;
  final Timestamp createdAt;
  final String createdBy;
  final Timestamp updatedAt;
  final String updatedBy;
  final int viewCount;
  final String seoKeywords;

  ContentPage({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.content,
    required this.contentType,
    required this.tags,
    required this.status,
    required this.publishedAt,
    required this.publishedBy,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.viewCount,
    required this.seoKeywords,
  });

  /// Create from Firestore document snapshot
  factory ContentPage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentPage(
      id: doc.id,
      slug: data['slug'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      contentType: data['contentType'] ?? 'HTML',
      tags: List<String>.from(data['tags'] ?? []),
      status: data['status'] ?? 'draft',
      publishedAt: data['publishedAt'] ?? Timestamp.now(),
      publishedBy: data['publishedBy'] ?? 'system',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? 'system',
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      updatedBy: data['updatedBy'] ?? 'system',
      viewCount: data['viewCount'] ?? 0,
      seoKeywords: data['seoKeywords'] ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'slug': slug,
      'title': title,
      'description': description,
      'content': content,
      'contentType': contentType,
      'tags': tags,
      'status': status,
      'publishedAt': publishedAt,
      'publishedBy': publishedBy,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'viewCount': viewCount,
      'seoKeywords': seoKeywords,
    };
  }

  /// Check if page is published and not expired
  bool get isPublished => status == 'published';

  /// Extract first 100 characters for preview
  String getPreview({int maxLength = 100}) {
    final text = content.replaceAll(RegExp(r'<[^>]*>'), '');
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    }
    return text;
  }
}
