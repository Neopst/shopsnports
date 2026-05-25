import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice notes
class InvoiceNote {
  final String id;
  final String invoiceId;
  final String content;
  final NoteType type;
  final bool isInternal;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isPinned;
  final List<String> mentionedUsers;
  final Map<String, dynamic> metadata;

  InvoiceNote({
    required this.id,
    required this.invoiceId,
    required this.content,
    required this.type,
    this.isInternal = true,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.attachmentUrl,
    this.attachmentName,
    this.isPinned = false,
    this.mentionedUsers = const [],
    this.metadata = const {},
  });

  factory InvoiceNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceNote(
      id: doc.id,
      invoiceId: data['invoiceId'] as String,
      content: data['content'] as String,
      type: NoteType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NoteType.general,
      ),
      isInternal: data['isInternal'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] as String,
      updatedBy: data['updatedBy'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentName: data['attachmentName'] as String?,
      isPinned: data['isPinned'] as bool? ?? false,
      mentionedUsers: (data['mentionedUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceId': invoiceId,
      'content': content,
      'type': type.name,
      'isInternal': isInternal,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'isPinned': isPinned,
      'mentionedUsers': mentionedUsers,
      'metadata': metadata,
    };
  }

  InvoiceNote copyWith({
    String? id,
    String? invoiceId,
    String? content,
    NoteType? type,
    bool? isInternal,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? attachmentUrl,
    String? attachmentName,
    bool? isPinned,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
  }) {
    return InvoiceNote(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      content: content ?? this.content,
      type: type ?? this.type,
      isInternal: isInternal ?? this.isInternal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      isPinned: isPinned ?? this.isPinned,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Note type
enum NoteType {
  general,
  payment,
  dispute,
  reminder,
  followUp,
  internal,
  customer,
  system,
}