import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Colors
  static const primaryStudent = Color(0xFF6C63FF); // Deep Purple
  static const primaryDriver = Color(0xFF00BFA6);  // Teal
  static const primaryAdmin = Color(0xFFFF6584);   // Hot Pink
  static const darkBackground = Color(0xFF1A1A2E);
  static const lightBackground = Color(0xFFF3F4F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryStudent,
        background: lightBackground,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(), // Modern Typography
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}