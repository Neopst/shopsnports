import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for notification localization
class NotificationLocalization {
  final String id;
  final String key;
  final Map<String, String> translations; // languageCode -> translatedText
  final String defaultLanguage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationLocalization({
    required this.id,
    required this.key,
    required this.translations,
    required this.defaultLanguage,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationLocalization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationLocalization(
      id: doc.id,
      key: data['key'] ?? '',
      translations: Map<String, String>.from(data['translations'] ?? {}),
      defaultLanguage: data['defaultLanguage'] ?? 'en',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'key': key,
      'translations': translations,
      'defaultLanguage': defaultLanguage,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String getTranslation(String languageCode) {
    return translations[languageCode] ?? translations[defaultLanguage] ?? key;
  }

  NotificationLocalization copyWith({
    String? id,
    String? key,
    Map<String, String>? translations,
    String? defaultLanguage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationLocalization(
      id: id ?? this.id,
      key: key ?? this.key,
      translations: translations ?? this.translations,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Supported languages
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<SupportedLanguage> all = [
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    SupportedLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    SupportedLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    SupportedLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    SupportedLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    SupportedLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
    ),
    SupportedLanguage(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    SupportedLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    SupportedLanguage(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
    SupportedLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
    SupportedLanguage(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
    SupportedLanguage(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
  ];

  static SupportedLanguage? fromCode(String code) {
    try {
      return all.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
}