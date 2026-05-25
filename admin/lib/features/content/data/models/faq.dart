import 'package:cloud_firestore/cloud_firestore.dart';

/// FAQ model - frequently asked questions
class FAQ {
  final String id;
  final String question;
  final String answer; // Can be HTML/Markdown
  final String category; // Orders, Payments, Returns, Shipping, etc.
  final int viewCount;
  final bool isActive;
  final int displayOrder;
  final List<String> keywords; // For search
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.viewCount,
    required this.isActive,
    required this.displayOrder,
    required this.keywords,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  FAQ copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    int? viewCount,
    bool? isActive,
    int? displayOrder,
    List<String>? keywords,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return FAQ(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      viewCount: viewCount ?? this.viewCount,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'viewCount': viewCount,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'keywords': keywords,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory FAQ.fromMap(Map<String, dynamic> map, String docId) {
    return FAQ(
      id: docId,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'General',
      viewCount: map['viewCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      displayOrder: map['displayOrder'] ?? 0,
      keywords: List<String>.from(map['keywords'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? 'unknown',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      updatedBy: map['updatedBy'] ?? 'unknown',
    );
  }

  factory FAQ.empty() {
    final now = DateTime.now();
    return FAQ(
      id: '',
      question: '',
      answer: '',
      category: 'General',
      viewCount: 0,
      isActive: true,
      displayOrder: 0,
      keywords: [],
      createdAt: now,
      createdBy: '',
      updatedAt: now,
      updatedBy: '',
    );
  }

  @override
  String toString() => 'FAQ(id: $id, question: $question, category: $category)';
}
