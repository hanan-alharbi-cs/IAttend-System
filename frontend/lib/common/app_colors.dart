import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF0B163F);
  static const Color primaryPurple = Color(0xFF4C1D95);
  static const Color cardBackground = Color(0xFFEDEBFF);
  static const Color textLight = Color(0xFFF4F4FF);
  static const Color textDark = Color(0xFF131A33);
  static const Color accentGreen = Color(0xFF22C55E);

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryPurple],
  );
}
