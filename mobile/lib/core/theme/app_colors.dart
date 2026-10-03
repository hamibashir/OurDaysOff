import 'package:flutter/material.dart';

/// Design tokens matching the Our Days Off web design palette
class AppColors {
  AppColors._();

  // Primary Teal Palette
  static const Color primary = Color(0xFF2B7A72);
  static const Color primaryLight = Color(0xFF81D8D0);
  static const Color primaryDark = Color(0xFF1D5E57);
  static const Color primarySurface = Color(0x1F81D8D0); // 12% opacity mint

  // Neutral Background & Surfaces
  static const Color scaffoldBackground = Color(0xFFFAF9F6); // Warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF3F1EC);
  static const Color border = Color(0xFFE8E5DF);
  static const Color borderLight = Color(0xFFF0EFEA);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1F2223);
  static const Color textMuted = Color(0xFF656A6D);
  static const Color textSubtle = Color(0xFF959A9E);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Accent & Decorative Colors
  static const Color accentViolet = Color(0xFF8C6DBE);
  static const Color accentLavender = Color(0xFFAE82D9);
  static const Color accentLime = Color(0xFFD7D982);
  static const Color accentGold = Color(0xFF5C5E1A);

  // Schedule & Shift Status Colors
  static const Color statusAvailable = Color(0xFF10B981); // Emerald Green (Day Off / Free)
  static const Color statusAvailableBg = Color(0xFFECFDF5);
  static const Color statusAvailableBorder = Color(0xFFA7F3D0);

  static const Color statusBusy = Color(0xFF3B82F6); // Blue (Work Shift)
  static const Color statusBusyBg = Color(0xFFEFF6FF);
  static const Color statusBusyBorder = Color(0xFFBFDBFE);

  static const Color statusLeave = Color(0xFFF59E0B); // Amber (Annual / Sick Leave)
  static const Color statusLeaveBg = Color(0xFFFFFBEB);
  static const Color statusLeaveBorder = Color(0xFFFDE68A);

  static const Color statusOvernight = Color(0xFF8B5CF6); // Purple (Night / Overnight)
  static const Color statusOvernightBg = Color(0xFFF5F3FF);
  static const Color statusOvernightBorder = Color(0xFFDDD6FE);

  // Action / Feedback
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF45ACA3), Color(0xFF65A3B3), Color(0xFF8C6DBE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF81D8D0), Color(0xFFAE82D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
