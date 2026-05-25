import 'package:cloud_firestore/cloud_firestore.dart';

enum ThemePreference { light, dark, system }

/// User preferences - personal admin settings
class UserPreferences {
  final String userId; // Firebase UID
  final ThemePreference theme;
  final String language; // 'en', 'es', 'fr', etc.
  final String timezone; // 'UTC', 'America/New_York', etc.
  final bool enableNotifications;
  final bool enableEmailNotifications;
  final bool enablePushNotifications;
  final bool enableInAppNotifications;
  final String? quietHoursStart; // "22:00"
  final String? quietHoursEnd; // "08:00"
  final bool enableTwoFactor;
  final String? phoneNumberFor2FA;
  final List<String> favoriteModules; // Recently used modules
  final bool sidebarCollapsed;
  final String dateFormat; // 'MM/dd/yyyy', 'dd/MM/yyyy'
  final String currencyFormat; // 'USD', 'EUR'
  final DateTime lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    required this.theme,
    required this.language,
    required this.timezone,
    required this.enableNotifications,
    required this.enableEmailNotifications,
    required this.enablePushNotifications,
    required this.enableInAppNotifications,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.enableTwoFactor,
    this.phoneNumberFor2FA,
    required this.favoriteModules,
    required this.sidebarCollapsed,
    required this.dateFormat,
    required this.currencyFormat,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  UserPreferences copyWith({
    String? userId,
    ThemePreference? theme,
    String? language,
    String? timezone,
    bool? enableNotifications,
    bool? enableEmailNotifications,
    bool? enablePushNotifications,
    bool? enableInAppNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? enableTwoFactor,
    String? phoneNumberFor2FA,
    List<String>? favoriteModules,
    bool? sidebarCollapsed,
    String? dateFormat,
    String? currencyFormat,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableEmailNotifications:
          enableEmailNotifications ?? this.enableEmailNotifications,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableInAppNotifications:
          enableInAppNotifications ?? this.enableInAppNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      enableTwoFactor: enableTwoFactor ?? this.enableTwoFactor,
      phoneNumberFor2FA: phoneNumberFor2FA ?? this.phoneNumberFor2FA,
      favoriteModules: favoriteModules ?? this.favoriteModules,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      dateFormat: dateFormat ?? this.dateFormat,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'theme': theme.name,
      'language': language,
      'timezone': timezone,
      'enableNotifications': enableNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enablePushNotifications': enablePushNotifications,
      'enableInAppNotifications': enableInAppNotifications,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'enableTwoFactor': enableTwoFactor,
      'phoneNumberFor2FA': phoneNumberFor2FA,
      'favoriteModules': favoriteModules,
      'sidebarCollapsed': sidebarCollapsed,
      'dateFormat': dateFormat,
      'currencyFormat': currencyFormat,
      'lastLogin': Timestamp.fromDate(lastLogin),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map, String userId) {
    return UserPreferences(
      userId: userId,
      theme: ThemePreference.values.byName(map['theme'] ?? 'system'),
      language: map['language'] ?? 'en',
      timezone: map['timezone'] ?? 'UTC',
      enableNotifications: map['enableNotifications'] ?? true,
      enableEmailNotifications: map['enableEmailNotifications'] ?? true,
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      enableInAppNotifications: map['enableInAppNotifications'] ?? true,
      quietHoursStart: map['quietHoursStart'],
      quietHoursEnd: map['quietHoursEnd'],
      enableTwoFactor: map['enableTwoFactor'] ?? false,
      phoneNumberFor2FA: map['phoneNumberFor2FA'],
      favoriteModules: List<String>.from(map['favoriteModules'] ?? []),
      sidebarCollapsed: map['sidebarCollapsed'] ?? false,
      dateFormat: map['dateFormat'] ?? 'MM/dd/yyyy',
      currencyFormat: map['currencyFormat'] ?? 'USD',
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserPreferences.defaults(String userId) {
    final now = DateTime.now();
    return UserPreferences(
      userId: userId,
      theme: ThemePreference.system,
      language: 'en',
      timezone: 'UTC',
      enableNotifications: true,
      enableEmailNotifications: true,
      enablePushNotifications: false,
      enableInAppNotifications: true,
      enableTwoFactor: false,
      favoriteModules: [],
      sidebarCollapsed: false,
      dateFormat: 'MM/dd/yyyy',
      currencyFormat: 'USD',
      lastLogin: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() =>
      'UserPreferences(userId: $userId, theme: $theme, language: $language)';
}
