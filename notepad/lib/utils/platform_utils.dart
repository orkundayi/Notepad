import 'package:flutter/material.dart';

class PlatformUtils {
  // Platform detection - Web only
  static const bool isWeb = true;
  static const bool isMobile = false;

  // Screen size helpers for web
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 1440;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 768 &&
        MediaQuery.of(context).size.width <= 1440;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <= 768;
  }

  static bool isDesktopSize(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // Layout helpers optimized for web
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1600) return 1400;
    if (screenWidth > 1200) return screenWidth * 0.9;
    if (screenWidth > 768) return screenWidth * 0.95;
    return screenWidth * 0.98;
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    if (isLargeScreen(context)) return const EdgeInsets.all(40);
    if (isMediumScreen(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  static EdgeInsets getCardPadding() {
    return const EdgeInsets.all(20);
  }

  static EdgeInsets getDialogPadding() {
    return const EdgeInsets.all(32);
  }

  static double getCardElevation() {
    return 0.0; // Web'de flat design
  }

  static BorderRadius getCardRadius() {
    return BorderRadius.circular(16.0);
  }

  static BorderRadius getButtonRadius() {
    return BorderRadius.circular(12.0);
  }

  static double getIconSize() {
    return 24.0;
  }

  static double getAppBarHeight() {
    return 72.0;
  }

  // Web-specific responsive text styles
  static TextStyle getHeadingStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
    } else if (width > 768) {
      return const TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
    } else {
      return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    }
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return const TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
    } else if (width > 768) {
      return const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    } else {
      return const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    }
  }

  static TextStyle getBodyStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return const TextStyle(fontSize: 16);
    } else if (width > 768) {
      return const TextStyle(fontSize: 14);
    } else {
      return const TextStyle(fontSize: 13);
    }
  }

  // Web-specific layout constants
  static double getSidebarWidth(BuildContext context) {
    if (isLargeScreen(context)) return 280;
    if (isMediumScreen(context)) return 240;
    return 200;
  }

  static double getMaxDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 900;
    if (screenWidth > 768) return screenWidth * 0.8;
    return screenWidth * 0.95;
  }

  // Kanban specific
  static int getKanbanColumns(BuildContext context) {
    if (isLargeScreen(context)) return 4;
    if (isMediumScreen(context)) return 3;
    return 1;
  }

  static bool shouldShowSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width > 1024;
  }

  // Performance optimizations
  static Duration getDefaultAnimationDuration() {
    return const Duration(milliseconds: 250);
  }

  static Duration getFastAnimationDuration() {
    return const Duration(milliseconds: 150);
  }

  // Task card sizing
  static double getTaskCardWidth(BuildContext context) {
    final padding = getPagePadding(context).horizontal;
    final availableWidth = MediaQuery.of(context).size.width - padding;

    if (isLargeScreen(context)) {
      return (availableWidth / 4) - 20; // 4 columns
    } else if (isMediumScreen(context)) {
      return (availableWidth / 3) - 20; // 3 columns
    } else {
      return availableWidth - 20; // 1 column
    }
  }

  static double getTaskCardMinHeight() {
    return 120;
  }

  // Missing methods needed by other components
  static bool isMobileSize(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static double getSpacing(double multiplier) {
    return 8.0 * multiplier;
  }

  static double getDialogMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 800;
    if (screenWidth > 768) return screenWidth * 0.7;
    return screenWidth * 0.9;
  }

  static TextStyle getTitleStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
    } else if (width > 768) {
      return const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
    } else {
      return const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
    }
  }

  static TextStyle getCaptionStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4);
    } else if (width > 768) {
      return TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4);
    } else {
      return TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4);
    }
  }
}
