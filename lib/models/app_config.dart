import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Application configuration and contact information
class AppConfig {
  final String supportPhone;
  final String supportWhatsapp;
  final String supportEmail;
  final String techSupportEmail;
  final String faqUrl;
  final ThemeConfig theme;
  final FeaturesConfig features;
  final String appVersion;
  final String minRequiredVersion;
  final Timestamp updatedAt;
  final String updatedBy;

  AppConfig({
    required this.supportPhone,
    required this.supportWhatsapp,
    required this.supportEmail,
    required this.techSupportEmail,
    required this.faqUrl,
    required this.theme,
    required this.features,
    required this.appVersion,
    required this.minRequiredVersion,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Create from Firestore document snapshot
  factory AppConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppConfig(
      supportPhone: data['supportPhone'] ?? '+234 XXX XXX XXXX',
      supportWhatsapp: data['supportWhatsapp'] ?? '+234 XXX XXX XXXX',
      supportEmail: data['supportEmail'] ?? 'support@shopsnports.com',
      techSupportEmail: data['techSupportEmail'] ?? 'tech@shopsnports.com',
      faqUrl: data['faqUrl'] ?? 'https://shopsnports.com/faq',
      theme: ThemeConfig.fromMap(data['theme'] ?? {}),
      features: FeaturesConfig.fromMap(data['features'] ?? {}),
      appVersion: data['appVersion'] ?? '1.0.0',
      minRequiredVersion: data['minRequiredVersion'] ?? '1.0.0',
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      updatedBy: data['updatedBy'] ?? 'system',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'supportPhone': supportPhone,
      'supportWhatsapp': supportWhatsapp,
      'supportEmail': supportEmail,
      'techSupportEmail': techSupportEmail,
      'faqUrl': faqUrl,
      'theme': theme.toMap(),
      'features': features.toMap(),
      'appVersion': appVersion,
      'minRequiredVersion': minRequiredVersion,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  /// Check if app version is supported
  bool isSupportedVersion(String currentVersion) {
    return _compareVersions(currentVersion, minRequiredVersion) >= 0;
  }

  /// Helper to compare semantic versions
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1 = v1Parts[i];
      final v2 = v2Parts[i];
      if (v1 > v2) return 1;
      if (v1 < v2) return -1;
    }
    return 0;
  }
}

/// Theme configuration colors
class ThemeConfig {
  final String primaryColor;
  final String accentColor;
  final String successColor;
  final String warningColor;
  final String errorColor;

  ThemeConfig({
    required this.primaryColor,
    required this.accentColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
  });

  factory ThemeConfig.fromMap(Map<String, dynamic> map) {
    return ThemeConfig(
      primaryColor: map['primaryColor'] ?? '#003366',
      accentColor: map['accentColor'] ?? '#FFB81C',
      successColor: map['successColor'] ?? '#27AE60',
      warningColor: map['warningColor'] ?? '#E67E22',
      errorColor: map['errorColor'] ?? '#E74C3C',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'accentColor': accentColor,
      'successColor': successColor,
      'warningColor': warningColor,
      'errorColor': errorColor,
    };
  }

  /// Parse hex color string to Color object
  Color getPrimaryColor() => _hexToColor(primaryColor);
  Color getAccentColor() => _hexToColor(accentColor);
  Color getSuccessColor() => _hexToColor(successColor);
  Color getWarningColor() => _hexToColor(warningColor);
  Color getErrorColor() => _hexToColor(errorColor);

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (!hexString.startsWith('#')) buffer.write('#');
    buffer.write(hexString);

    final hex = buffer.toString().replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Features configuration
class FeaturesConfig {
  final bool analyticsEnabled;
  final bool affiliateProgramActive;
  final bool maintenanceMode;

  FeaturesConfig({
    required this.analyticsEnabled,
    required this.affiliateProgramActive,
    required this.maintenanceMode,
  });

  factory FeaturesConfig.fromMap(Map<String, dynamic> map) {
    return FeaturesConfig(
      analyticsEnabled: map['analyticsEnabled'] ?? true,
      affiliateProgramActive: map['affiliateProgramActive'] ?? true,
      maintenanceMode: map['maintenanceMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'analyticsEnabled': analyticsEnabled,
      'affiliateProgramActive': affiliateProgramActive,
      'maintenanceMode': maintenanceMode,
    };
  }
}
