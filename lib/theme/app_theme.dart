import 'package:flutter/material.dart';

class AppTheme {
  static const Color tealPrimary   = Color(0xFF4DD0C4);
  static const Color tealDark      = Color(0xFF2A7A74);
  static const Color tealMid       = Color(0xFF3A9990);
  static const Color skyBlue       = Color(0xFF6FC8E8);
  static const Color orange        = Color(0xFFF4A742);
  static const Color pink          = Color(0xFFE8A0BF);
  static const Color bgTop         = Color(0xFFB8F0E8);
  static const Color bgMid         = Color(0xFF7FD8D0);
  static const Color bgBottom      = Color(0xFFAEE8F8);

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgTop, bgMid, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration get backgroundDecoration =>
      const BoxDecoration(gradient: bgGradient);

  static BoxDecoration cardDecoration({Color? shadowColor}) => BoxDecoration(
    color: Colors.white.withOpacity(0.88),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: (shadowColor ?? tealPrimary).withOpacity(0.15),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}