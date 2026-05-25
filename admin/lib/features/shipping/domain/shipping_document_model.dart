// FILE: lib/features/shipping/domain/shipping_document_model.dart

enum DocumentType {
  invoice,
  packingList,
  customsDeclaration,
  proofOfPayment,
  insuranceCertificate,
  shippingLabel,
  billOfLading,
  exportPermit,
  certificateOfOrigin,
  other,
}

enum DocumentStatus { pending, verified, rejected }

class ShippingDocument {
  final String id;
  final String name;
  final String url; // Firebase Storage download URL
  final String storagePath; // Firebase Storage path (for deletion)
  final DocumentType type;
  final DocumentStatus status;
  final int sizeInBytes;
  final String mimeType; // e.g., 'application/pdf', 'image/jpeg'
  final DateTime uploadedAt;
  final String uploadedBy; // User ID who uploaded
  final String? notes;
  final String? rejectionReason;

  ShippingDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.storagePath,
    required this.type,
    this.status = DocumentStatus.pending,
    required this.sizeInBytes,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploadedBy,
    this.notes,
    this.rejectionReason,
  });

  // Human-readable file size
  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get file extension from name
  String get extension => name.split('.').last.toUpperCase();

  // Check if it's an image
  bool get isImage =>
      mimeType.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension.toLowerCase());

  // Check if it's a PDF
  bool get isPdf =>
      mimeType == 'application/pdf' || extension.toLowerCase() == 'pdf';

  // Check if it can be previewed in browser
  bool get isPreviewable => isImage || isPdf;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'storagePath': storagePath,
      'type': type.name,
      'status': status.name,
      'sizeInBytes': sizeInBytes,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
      'notes': notes,
      'rejectionReason': rejectionReason,
    };
  }

  factory ShippingDocument.fromMap(Map<String, dynamic> map) {
    return ShippingDocument(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      storagePath: map['storagePath'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DocumentStatus.pending,
      ),
      sizeInBytes: map['sizeInBytes'] ?? 0,
      mimeType: map['mimeType'] ?? '',
      uploadedAt: DateTime.parse(
        map['uploadedAt'] ?? DateTime.now().toIso8601String(),
      ),
      uploadedBy: map['uploadedBy'] ?? '',
      notes: map['notes'],
      rejectionReason: map['rejectionReason'],
    );
  }

  ShippingDocument copyWith({
    String? id,
    String? name,
    String? url,
    String? storagePath,
    DocumentType? type,
    DocumentStatus? status,
    int? sizeInBytes,
    String? mimeType,
    DateTime? uploadedAt,
    String? uploadedBy,
    String? notes,
    String? rejectionReason,
  }) {
    return ShippingDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      storagePath: storagePath ?? this.storagePath,
      type: type ?? this.type,
      status: status ?? this.status,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
