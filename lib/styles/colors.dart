import 'package:flutter/material.dart';

/// Centralized color palette for the app.
/// Includes aliases used across the project for backwards compatibility.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF0A2463);
  static const Color primaryColor = primary; // alias

  static const Color accent = Color(0xFFFFC107);
  static const Color accentColor = accent; // alias

  // Backgrounds / surfaces
  static const Color background = Color(0xFFF8F8FA);
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color muted = Color(0xFF9AA0B2);
  static const Color textSecondary = Color(0xFF6B7280); // alias used in widgets

  // Status
  static const Color success =
      Color(0xFF0A2463); // Deep blue for success actions
  static const Color danger = Color(0xFFe74c3c);
  static const Color warning =
      Color(0xFFFFC107); // Deep yellow for warnings/highlights

  // Borders
  static const Color border = Color(0xFFE5E7EB);
}
