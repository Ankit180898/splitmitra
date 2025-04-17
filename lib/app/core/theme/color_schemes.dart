import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF7F3DFF); // Main purple brand color
  static const Color secondary = Color(0xFF0077FF); // Blue secondary color
  static const Color accent = Color(0xFFFCAC12); // Yellow accent color

  // Status Colors
  static const Color success = Color(0xFF00A86B); // Green for success states
  static const Color warning = Color(0xFFFCAC12); // Amber/Yellow for warnings
  static const Color error = Color(0xFFFD3C4A); // Red for errors
  static const Color info = Color(0xFF0077FF); // Blue for information

  // Transaction Status Colors
  static const Color settled = Color(
    0xFF00A86B,
  ); // Green for settled transactions
  static const Color pending = Color(
    0xFFFCAC12,
  ); // Yellow for pending transactions
  static const Color overdue = Color(
    0xFFFD3C4A,
  ); // Red for overdue transactions

  // Light Theme
  static const Color lightBackground = Color(
    0xFFF6F6F6,
  ); // Light gray background
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF292B2D); // Almost black
  static const Color lightTextSecondary = Color(
    0xFF91919F,
  ); // Gray secondary text
  static const Color lightDivider = Color(0xFFEEEEF0); // Light gray divider

  // Dark Theme
  static const Color darkBackground = Color(0xFF161719); // Very dark gray/black
  static const Color darkSurface = Color(0xFF222222); // Dark surface
  static const Color darkText = Color(0xFFF2F2F2); // Almost white
  static const Color darkTextSecondary = Color(0xFFAFAFAF); // Light gray text
  static const Color darkDivider = Color(0xFF353542); // Dark divider

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF9A6AFF)], // Purple gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFFD465)], // Yellow/amber gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient errorGradient = LinearGradient(
    colors: [
      error,
      Color(0xFFD32F2F), // Darker red for gradient
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient successGradient = LinearGradient(
    colors: [
      success,
      Color(0xFF007B4F), // Darker green for gradient
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Expense Category Colors
  static const Color foodDrink = Color(0xFFFD3C4A); // Red for food/drinks
  static const Color shopping = Color(0xFF7F3DFF); // Purple for shopping
  static const Color travel = Color(0xFF0077FF); // Blue for travel
  static const Color entertainment = Color(
    0xFF00A86B,
  ); // Green for entertainment
  static const Color utilities = Color(0xFFFCAC12); // Yellow for utilities
  static const Color home = Color(0xFF7F3DFF); // Purple for home expenses
  static const Color other = Color(0xFF91919F); // Gray for other expenses

  // Group Member Status Colors
  static const Color active = Color(0xFF00A86B); // Green for active members
  static const Color inactive = Color(0xFF91919F); // Gray for inactive members
  static const Color invited = Color(0xFFFCAC12); // Yellow for invited members
}
