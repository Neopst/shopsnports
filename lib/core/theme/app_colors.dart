import 'package:flutter/material.dart';

/// ShopsNPorts App Color Scheme
/// Deep Blue (#003366) + Deep Yellow (#FFB81C) Theme
class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF003366); // Deep Blue
  static const Color accentYellow = Color(0xFFFFB81C); // Deep Yellow

  // Secondary Colors
  static const Color successGreen = Color(0xFF27AE60); // Green
  static const Color warningOrange = Color(0xFFE67E22); // Orange
  static const Color errorRed = Color(0xFFE74C3C); // Red

  // Neutral Colors
  static const Color darkGrey = Color(0xFF2C3E50); // Dark Grey
  static const Color grey = Color(0xFF7F8C8D); // Medium Grey
  static const Color lightGrey = Color(0xFFECF0F1); // Light Grey
  static const Color extraLightGrey = Color(0xFFF8F9FA); // Extra Light
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color black = Color(0xFF000000); // Black

  // Semantic Colors
  static const Color positive = successGreen;
  static const Color warning = warningOrange;
  static const Color negative = errorRed;
  static const Color info = primaryBlue;

  // Status Colors
  static const Color statusPending = warningOrange;
  static const Color statusInTransit = primaryBlue;
  static const Color statusDelivered = successGreen;
  static const Color statusCancelled = errorRed;

  // Transparency Variants
  static Color primaryBlueTrans(double opacity) =>
      primaryBlue.withValues(alpha: opacity);
  static Color accentYellowTrans(double opacity) =>
      accentYellow.withValues(alpha: opacity);
  static Color darkGreyTrans(double opacity) => darkGrey.withValues(alpha: opacity);
  static Color whiteTrans(double opacity) => white.withValues(alpha: opacity);

  // Material Color (for theme configuration)
  static MaterialColor createMaterialColor(Color color) {
    final int red = (color.r * 255).round();
    final int green = (color.g * 255).round();
    final int blue = (color.b * 255).round();

    final Map<int, Color> shades = {
      50: Color.fromARGB(255, red + 20, green + 20, blue + 20),
      100: Color.fromARGB(255, red + 15, green + 15, blue + 15),
      200: Color.fromARGB(255, red + 10, green + 10, blue + 10),
      300: Color.fromARGB(255, red + 5, green + 5, blue + 5),
      400: Color.fromARGB(255, red + 2, green + 2, blue + 2),
      500: color,
      600: Color.fromARGB(255, red - 5, green - 5, blue - 5),
      700: Color.fromARGB(255, red - 10, green - 10, blue - 10),
      800: Color.fromARGB(255, red - 15, green - 15, blue - 15),
      900: Color.fromARGB(255, red - 20, green - 20, blue - 20),
    };
    return MaterialColor(color.toARGB32(), shades);
  }
}
