import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentStatus { draft, published, archived }

/// Content page model - for CMS pages, help docs, terms, privacy, etc.
class ContentPage {
  final String id;
  final String slug; // URL-friendly identifier
  final String title;
  final String description; // Meta description
  final String content; // HTML or Markdown
  final String contentType; // TEXT, HTML, MARKDOWN
  final List<String> tags; // Categories/tags
  final ContentStatus status;
  final DateTime? publishedAt;
  final String? publishedBy; // Admin ID who published
  final DateTime createdAt;
  final String createdBy; // Admin ID
  final DateTime updatedAt;
  final String updatedBy; // Admin ID
  final int viewCount;

  ContentPage({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.content,
    required this.contentType,
    required this.tags,
    required this.status,
    this.publishedAt,
    this.publishedBy,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.viewCount,
  });

  bool get isPublished => status == ContentStatus.published;

  ContentPage copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    String? content,
    String? contentType,
    List<String>? tags,
    ContentStatus? status,
    DateTime? publishedAt,
    String? publishedBy,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    int? viewCount,
  }) {
    return ContentPage(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'description': description,
      'content': content,
      'contentType': contentType,
      'tags': tags,
      'status': status.name,
      'publishedAt': publishedAt != null
          ? Timestamp.fromDate(publishedAt!)
          : null,
      'publishedBy': publishedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'viewCount': viewCount,
    };
  }

  factory ContentPage.fromMap(Map<String, dynamic> map, String docId) {
    return ContentPage(
      id: docId,
      slug: map['slug'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      content: map['content'] ?? '',
      contentType: map['contentType'] ?? 'TEXT',
      tags: List<String>.from(map['tags'] ?? []),
      status: ContentStatus.values.byName(map['status'] ?? 'draft'),
      publishedAt: (map['publishedAt'] as Timestamp?)?.toDate(),
      publishedBy: map['publishedBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? 'unknown',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] ?? 'unknown',
      viewCount: map['viewCount'] ?? 0,
    );
  }

  factory ContentPage.empty() {
    final now = DateTime.now();
    return ContentPage(
      id: '',
      slug: '',
      title: '',
      description: '',
      content: '',
      contentType: 'HTML',
      tags: [],
      status: ContentStatus.draft,
      createdAt: now,
      createdBy: '',
      updatedAt: now,
      updatedBy: '',
      viewCount: 0,
    );
  }

  @override
  String toString() =>
      'ContentPage(id: $id, slug: $slug, title: $title, status: $status)';
}
