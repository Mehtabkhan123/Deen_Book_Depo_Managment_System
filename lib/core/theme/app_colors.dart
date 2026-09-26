import 'package:flutter/material.dart';

/// Centralized color palette for the Offline Wholesale Book Management System
class AppColors {
  AppColors._();

  // Primary Brand Colors (Deep Corporate Navy)
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryContainer = Color(0xFFEFF6FF); // Soft Blue Tint

  // Accent & Secondary Colors (Professional Slate Teal)
  static const Color secondary = Color(0xFF0D9488); // Slate Teal
  static const Color secondaryHover = Color(0xFF0F766E);
  static const Color secondaryContainer = Color(0xFFF0FDFA);

  // Surface & Background Colors
  static const Color background = Color(0xFFF8FAFC); // Clean neutral slate background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Neutral Color Scale (Slate)
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Sidebar Specific Palette (Dark Enterprise Theme)
  static const Color sidebarBackground = Color(0xFF0F172A); // Slate 900
  static const Color sidebarSelected = Color(0xFF1E293B); // Slate 800
  static const Color sidebarActive = Color(0xFF1E293B);
  static const Color sidebarHover = Color(0xFF1E293B);
  static const Color sidebarText = Color(0xFF94A3B8); // Slate 400
  static const Color sidebarTextMuted = Color(0xFF94A3B8);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarActiveText = Color(0xFFFFFFFF);
  static const Color sidebarBorder = Color(0xFF1E293B);

  // Top Bar Specific Palette
  static const Color topBarBackground = Color(0xFFFFFFFF);
  static const Color topBarBorder = Color(0xFFE2E8F0);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Semantic Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF15803D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorText = Color(0xFFB91C1C);

  static const Color info = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoText = Color(0xFF1D4ED8);
}
