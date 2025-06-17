import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);

  static const Color secondary = Color(0xFF757575);
  static const Color secondaryLight = Color(0xFF9E9E9E);

  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // Task status colors
  static const Color todoColor = Color(0xFF9E9E9E);
  static const Color inProgressColor = Color(0xFF2196F3);
  static const Color doneColor = Color(0xFF4CAF50);
  static const Color blockedColor = Color(0xFFF44336);

  // Card colors
  static const Color cardShadow = Color(0x1A000000);
  static const Color divider = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // FloatingActionButton theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
        return AppColors.todoColor;
      case 'in progress':
        return AppColors.inProgressColor;
      case 'done':
        return AppColors.doneColor;
      case 'blocked':
        return AppColors.blockedColor;
      default:
        return AppColors.todoColor;
    }
  }
}
