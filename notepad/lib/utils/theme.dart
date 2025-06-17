import 'package:flutter/material.dart';

class AppColors {
  // Modern professional color palette
  static const Color primary = Color(0xFF3B82F6); // Modern blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF93C5FD);

  static const Color secondary = Color(0xFF6B7280);
  static const Color secondaryLight = Color(0xFF9CA3AF);

  static const Color background = Color(0xFFF8FAFC); // Light gray-blue
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);

  // Enhanced task status colors with better contrast
  static const Color todoColor = Color(0xFF94A3B8); // Slate
  static const Color inProgressColor = Color(0xFF3B82F6); // Blue
  static const Color doneColor = Color(0xFF10B981); // Emerald
  static const Color blockedColor = Color(0xFFEF4444); // Red

  // Card and UI colors
  static const Color cardShadow = Color(0x0A000000);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Text colors with better hierarchy
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status specific background colors
  static const Color todoBackground = Color(0xFFF8FAFC);
  static const Color inProgressBackground = Color(0xFFF0F9FF);
  static const Color doneBackground = Color(0xFFF0FDF4);
  static const Color blockedBackground = Color(0xFFFEF2F2);
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
      case 'yapılacak':
        return AppColors.todoColor;
      case 'in progress':
      case 'devam ediyor':
        return AppColors.inProgressColor;
      case 'done':
      case 'tamamlandı':
        return AppColors.doneColor;
      case 'blocked':
      case 'bloke':
        return AppColors.blockedColor;
      default:
        return AppColors.todoColor;
    }
  }

  static Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
      case 'yapılacak':
        return AppColors.todoBackground;
      case 'in progress':
      case 'devam ediyor':
        return AppColors.inProgressBackground;
      case 'done':
      case 'tamamlandı':
        return AppColors.doneBackground;
      case 'blocked':
      case 'bloke':
        return AppColors.blockedBackground;
      default:
        return AppColors.todoBackground;
    }
  }

  // Responsive text styles
  static TextStyle getResponsiveTextStyle(
    BuildContext context, {
    double baseFontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = 1.0;

    if (screenWidth < 600) {
      scaleFactor = 0.9; // Mobile phones
    } else if (screenWidth < 1200) {
      scaleFactor = 1.0; // Tablets
    } else {
      scaleFactor = 1.1; // Desktop
    }

    return TextStyle(
      fontSize: baseFontSize * scaleFactor,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
    );
  }
}
