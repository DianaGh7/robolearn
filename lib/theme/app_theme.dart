import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors - softer, more kid-friendly
  static const Color tealPrimary   = Color(0xFF4DD0C4);
  static const Color tealDark      = Color(0xFF2A7A74);
  static const Color tealMid       = Color(0xFF3A9990);
  static const Color skyBlue       = Color(0xFF6FC8E8);
  static const Color orange        = Color(0xFFF4A742);
  static const Color pink          = Color(0xFFE8A0BF);
  
  // Background colors
  static const Color bgTop         = Color(0xFFB8F0E8);
  static const Color bgMid         = Color(0xFF7FD8D0);
  static const Color bgBottom      = Color(0xFFAEE8F8);

  // Success and feedback colors
  static const Color successGreen  = Color(0xFF4CAF50);
  static const Color errorRed      = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color streakFire    = Color(0xFFFF6B6B);

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgTop, bgMid, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration get backgroundDecoration =>
      const BoxDecoration(gradient: bgGradient);

  // Enhanced card decoration with softer shadows
  static BoxDecoration cardDecoration({Color? shadowColor}) => BoxDecoration(
    color: Colors.white.withOpacity(0.90),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: (shadowColor ?? tealPrimary).withOpacity(0.12),
        blurRadius: 12,
        offset: const Offset(0, 3),
        spreadRadius: 0,
      ),
    ],
  );

  // Text styles for kids - larger, clearer
  static TextStyle headlineStyle = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: tealDark,
    height: 1.3,
  );

  static TextStyle titleStyle = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: tealDark,
    height: 1.4,
  );

  static TextStyle bodyLargeStyle = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    height: 1.5,
  );

  static TextStyle bodyStyle = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
    height: 1.5,
  );

  static TextStyle labelStyle = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.grey.shade600,
    height: 1.4,
  );

  // Button styling for kids - larger touch targets
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF26A995), Color(0xFF19907C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF26A995).withOpacity(0.35),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Spacing constants
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // Border radius constants
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // Minimum touch target size for accessibility
  static const double minTouchTarget = 48.0;
}