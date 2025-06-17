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

  // Screen size helpers
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800 &&
        MediaQuery.of(context).size.width <= 1200;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <= 800;
  }

  // Layout helpers
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isWeb) {
      if (screenWidth > 1400) return 1200;
      if (screenWidth > 1000) return screenWidth * 0.85;
      return screenWidth * 0.95;
    }
    return screenWidth;
  }

  static EdgeInsets getPagePadding(BuildContext context) {
    if (isWeb) {
      if (isLargeScreen(context)) return const EdgeInsets.all(32);
      if (isMediumScreen(context)) return const EdgeInsets.all(24);
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(16);
  }

  static EdgeInsets getCardPadding() {
    return isWeb ? const EdgeInsets.all(20) : const EdgeInsets.all(16);
  }

  static EdgeInsets getDialogPadding() {
    return isWeb ? const EdgeInsets.all(32) : const EdgeInsets.all(20);
  }

  static double getCardElevation() {
    return isWeb ? 8.0 : 4.0;
  }

  static BorderRadius getCardRadius() {
    return BorderRadius.circular(isWeb ? 16.0 : 12.0);
  }

  static BorderRadius getButtonRadius() {
    return BorderRadius.circular(isWeb ? 12.0 : 8.0);
  }

  static double getIconSize() {
    return isWeb ? 24.0 : 20.0;
  }

  static double getAppBarHeight() {
    return isWeb ? 72.0 : 56.0;
  }

  // Typography helpers
  static TextStyle getTitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge!;
    return base.copyWith(
      fontSize: isWeb ? 24 : 20,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getSubtitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium!;
    return base.copyWith(
      fontSize: isWeb ? 18 : 16,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle getBodyStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge!;
    return base.copyWith(fontSize: isWeb ? 16 : 14);
  }

  static TextStyle getCaptionStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall!;
    return base.copyWith(fontSize: isWeb ? 14 : 12);
  }

  // Spacing helpers
  static double getSpacingUnit() {
    return isWeb ? 12.0 : 8.0;
  }

  static double getSpacing(double multiplier) {
    return getSpacingUnit() * multiplier;
  }

  // Button helpers
  static Size getButtonSize() {
    return isWeb ? const Size.fromHeight(48) : const Size.fromHeight(44);
  }

  static Size getMinButtonSize() {
    return isWeb ? const Size(120, 48) : const Size(88, 44);
  }

  // Animation durations
  static Duration getAnimationDuration() {
    return isWeb
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 150);
  }

  // Dialog sizes
  static double getDialogMaxWidth(BuildContext context) {
    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > 1200) return 600;
      if (screenWidth > 800) return 500;
      return 400;
    }
    return MediaQuery.of(context).size.width * 0.9;
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
