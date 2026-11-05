import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand palette
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800

  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF97316); // Orange 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Light Mode Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Preset habit colors for selection
  static const List<int> habitColorPresets = [
    0xFF4F46E5, // Indigo
    0xFF059669, // Emerald
    0xFFEA580C, // Orange
    0xFF0284C7, // Sky Blue
    0xFF9333EA, // Purple
    0xFFE11D48, // Rose
    0xFF0D9488, // Teal
    0xFFD97706, // Amber
    0xFF2563EB, // Blue
    0xFFDB2777, // Pink
  ];

  static Color getHabitColor(int code) {
    return Color(code);
  }
}
