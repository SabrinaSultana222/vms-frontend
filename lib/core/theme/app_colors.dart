import 'package:flutter/material.dart';

/// Semantic colors used throughout the VMS application.
class AppColors {
  // Brand / Primary palette
  static const Color primary = Color(0xFF1E40AF); // Deep Indigo / Cobalt
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Secondary / Accent
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryLight = Color(0xFF14B8A6);

  // Neutral & Surface
  static const Color background = Color(0xFFF8FAFC); // Cool slate background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status Colors (Badges, Alerts, Chips)
  static const Color statusActive = Color(0xFF16A34A); // Green
  static const Color statusActiveBg = Color(0xFFDCFCE7);

  static const Color statusMaintenance = Color(0xFFD97706); // Amber
  static const Color statusMaintenanceBg = Color(0xFFFEF3C7);

  static const Color statusInactive = Color(0xFFDC2626); // Red
  static const Color statusInactiveBg = Color(0xFFFEE2E2);

  static const Color statusReserved = Color(0xFF2563EB); // Blue
  static const Color statusReservedBg = Color(0xFFDBEAFE);

  // Private constructor to prevent instantiation
  AppColors._();
}
