import 'package:flutter/material.dart';

class AppTheme {
  static final Color deepBlue = const Color(0xFF0A2A66);
  static final Color deepYellow = const Color(0xFFF2B400);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepBlue,
        primary: deepBlue,
        secondary: deepYellow,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A2A66),
        foregroundColor: Colors.white,
      ),
    );
  }
}
