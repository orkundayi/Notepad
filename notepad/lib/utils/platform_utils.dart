import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformUtils {
  // Platform detection
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  // Screen size helpers with enhanced breakpoints
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

  static bool isMobileSize(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTabletSize(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1024;
  }

  static bool isDesktopSize(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // Layout helpers with responsive design
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isWeb) {
      if (screenWidth > 1600) return 1400;
      if (screenWidth > 1200) return screenWidth * 0.9;
      if (screenWidth > 768) return screenWidth * 0.95;
      return screenWidth * 0.98;
    }
    return screenWidth;
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    if (isWeb) {
      if (isLargeScreen(context)) return const EdgeInsets.all(40);
      if (isMediumScreen(context)) return const EdgeInsets.all(24);
      if (isMobileSize(context)) return const EdgeInsets.all(12);
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(16);
  }

  static EdgeInsets getCardPadding([BuildContext? context]) {
    if (context != null && isWeb) {
      if (isMobileSize(context)) return const EdgeInsets.all(12);
      return const EdgeInsets.all(20);
    }
    return isWeb ? const EdgeInsets.all(20) : const EdgeInsets.all(16);
  }

  static EdgeInsets getDialogPadding([BuildContext? context]) {
    if (context != null && isWeb) {
      if (isMobileSize(context)) return const EdgeInsets.all(16);
      return const EdgeInsets.all(32);
    }
    return isWeb ? const EdgeInsets.all(32) : const EdgeInsets.all(20);
  }

  static double getCardElevation() {
    return isWeb ? 0.0 : 4.0;
  }

  static BorderRadius getCardRadius([BuildContext? context]) {
    if (context != null && isWeb && isMobileSize(context)) {
      return BorderRadius.circular(12.0);
    }
    return BorderRadius.circular(isWeb ? 16.0 : 12.0);
  }

  static BorderRadius getButtonRadius() {
    return BorderRadius.circular(isWeb ? 12.0 : 8.0);
  }

  static double getIconSize([BuildContext? context]) {
    if (context != null && isWeb && isMobileSize(context)) return 20.0;
    return isWeb ? 24.0 : 20.0;
  }

  static double getAppBarHeight() {
    return isWeb ? 72.0 : 56.0;
  }

  // Responsive layout configurations
  static int getKanbanColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 1; // Mobile: single column
    if (screenWidth < 900) return 2; // Small tablet: 2 columns
    if (screenWidth < 1200) return 3; // Large tablet: 3 columns
    return 4; // Desktop: all 4 columns
  }

  static bool shouldShowSidebar(BuildContext context) {
    return isWeb && MediaQuery.of(context).size.width > 1024;
  }

  static double getSidebarWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1600) return 320;
    if (screenWidth > 1200) return 280;
    return 260;
  }

  // Typography helpers with responsive scaling
  static TextStyle getTitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge!;
    final screenWidth = MediaQuery.of(context).size.width;

    double fontSize = 20;
    if (isWeb) {
      if (screenWidth > 1200) {
        fontSize = 28;
      } else if (screenWidth > 768) {
        fontSize = 24;
      } else {
        fontSize = 20;
      }
    }

    return base.copyWith(fontSize: fontSize, fontWeight: FontWeight.w700);
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium!;
    final screenWidth = MediaQuery.of(context).size.width;

    double fontSize = 16;
    if (isWeb) {
      if (screenWidth > 1200) {
        fontSize = 20;
      } else if (screenWidth > 768) {
        fontSize = 18;
      } else {
        fontSize = 16;
      }
    }

    return base.copyWith(fontSize: fontSize, fontWeight: FontWeight.w600);
  }

  static TextStyle getBodyStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge!;
    final screenWidth = MediaQuery.of(context).size.width;

    double fontSize = 14;
    if (isWeb) {
      if (screenWidth > 1200) {
        fontSize = 16;
      } else if (screenWidth > 768) {
        fontSize = 15;
      } else {
        fontSize = 14;
      }
    }

    return base.copyWith(fontSize: fontSize);
  }

  static TextStyle getCaptionStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall!;
    final screenWidth = MediaQuery.of(context).size.width;

    double fontSize = 12;
    if (isWeb) {
      if (screenWidth > 1200) {
        fontSize = 14;
      } else if (screenWidth > 768) {
        fontSize = 13;
      } else {
        fontSize = 12;
      }
    }

    return base.copyWith(fontSize: fontSize);
  }

  // Task card responsive sizing
  static double getTaskCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = getKanbanColumns(context);
    final padding = getPagePadding(context).horizontal;
    final sidebarWidth =
        shouldShowSidebar(context) ? getSidebarWidth(context) : 0;

    final availableWidth = screenWidth - padding - sidebarWidth;
    final columnSpacing = 16.0 * (columns - 1);

    return (availableWidth - columnSpacing) / columns;
  }

  static double getTaskCardMinHeight() {
    return isWeb ? 120.0 : 100.0;
  }

  // Animation durations
  static Duration getDefaultAnimationDuration() {
    return const Duration(milliseconds: 300);
  }

  static Duration getFastAnimationDuration() {
    return const Duration(milliseconds: 150);
  }

  // Helper methods for backward compatibility
  static double getSpacing(double multiplier) {
    return 8.0 * multiplier;
  }

  static double getDialogMaxWidth([BuildContext? context]) {
    if (context != null && isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > 1200) return 600;
      if (screenWidth > 800) return 500;
      return screenWidth * 0.9;
    }
    return isWeb ? 600 : 400;
  }
}

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1600;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
