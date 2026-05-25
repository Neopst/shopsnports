import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification sound customization
class NotificationSound {
  final String id;
  final String name;
  final String description;
  final String soundUrl;
  final SoundCategory category;
  final int duration; // in seconds
  final bool isDefault;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationSound({
    required this.id,
    required this.name,
    required this.description,
    required this.soundUrl,
    required this.category,
    required this.duration,
    this.isDefault = false,
    this.isActive = true,
    this.usageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationSound.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSound(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      soundUrl: data['soundUrl'] ?? '',
      category: SoundCategory.fromString(data['category'] ?? 'default'),
      duration: data['duration'] ?? 0,
      isDefault: data['isDefault'] ?? false,
      isActive: data['isActive'] ?? true,
      usageCount: data['usageCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'soundUrl': soundUrl,
      'category': category.value,
      'duration': duration,
      'isDefault': isDefault,
      'isActive': isActive,
      'usageCount': usageCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  NotificationSound copyWith({
    String? id,
    String? name,
    String? description,
    String? soundUrl,
    SoundCategory? category,
    int? duration,
    bool? isDefault,
    bool? isActive,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSound(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      soundUrl: soundUrl ?? this.soundUrl,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum SoundCategory {
  defaultSound('default'),
  promotional('promotional'),
  alert('alert'),
  success('success'),
  warning('warning'),
  error('error'),
  custom('custom');

  final String value;
  const SoundCategory(this.value);

  static SoundCategory fromString(String value) {
    return SoundCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SoundCategory.defaultSound,
    );
  }
}