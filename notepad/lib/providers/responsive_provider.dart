import 'package:flutter/material.dart';

class ResponsiveProvider extends ChangeNotifier {
  late Size _screenSize;
  late bool _isMobile;
  late bool _isTablet;
  late bool _isDesktop;

  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;

  ResponsiveProvider() {
    _screenSize = const Size(0, 0);
    _isMobile = false;
    _isTablet = false;
    _isDesktop = true;
  }

  // Getters
  Size get screenSize => _screenSize;
  bool get isMobile => _isMobile;
  bool get isTablet => _isTablet;
  bool get isDesktop => _isDesktop;
  double get screenWidth => _screenSize.width;
  double get screenHeight => _screenSize.height;

  // Screen size kategorileri
  bool get isSmallMobile => _screenSize.width < 360;
  bool get isMediumMobile =>
      _screenSize.width >= 360 && _screenSize.width < 480;
  bool get isLargeMobile =>
      _screenSize.width >= 480 && _screenSize.width < mobileBreakpoint;
  bool get isSmallTablet =>
      _screenSize.width >= mobileBreakpoint && _screenSize.width < 900;
  bool get isLargeTablet =>
      _screenSize.width >= 900 && _screenSize.width < tabletBreakpoint;
  bool get isSmallDesktop =>
      _screenSize.width >= tabletBreakpoint && _screenSize.width < 1440;
  bool get isLargeDesktop => _screenSize.width >= 1440;

  // Orientation
  bool get isPortrait => _screenSize.height > _screenSize.width;
  bool get isLandscape => _screenSize.width > _screenSize.height;

  // Güncelleme metodu
  void updateScreenSize(Size newSize) {
    if (_screenSize != newSize) {
      _screenSize = newSize;
      _updateBreakpoints();
      notifyListeners();
    }
  }

  void _updateBreakpoints() {
    _isMobile = _screenSize.width <= mobileBreakpoint;
    _isTablet =
        _screenSize.width > mobileBreakpoint &&
        _screenSize.width <= tabletBreakpoint;
    _isDesktop = _screenSize.width > tabletBreakpoint;
  }

  // Helper metodları
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (_isMobile) return mobile;
    if (_isTablet && tablet != null) return tablet;
    return desktop;
  }

  double responsiveValue({
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    if (_isMobile) return mobile;
    if (_isTablet && tablet != null) return tablet;
    return desktop;
  }

  EdgeInsets responsivePadding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    required EdgeInsets desktop,
  }) {
    if (_isMobile) return mobile;
    if (_isTablet && tablet != null) return tablet;
    return desktop;
  }

  // Responsive values
  double get horizontalPadding =>
      responsiveValue(mobile: 16.0, tablet: 20.0, desktop: 24.0);

  double get verticalSpacing =>
      responsiveValue(mobile: 12.0, tablet: 16.0, desktop: 20.0);

  // Font sizes
  double get titleFontSize =>
      responsiveValue(mobile: 20.0, tablet: 22.0, desktop: 24.0);

  double get subtitleFontSize =>
      responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0);

  double get bodyFontSize =>
      responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0);

  double get captionFontSize =>
      responsiveValue(mobile: 11.0, tablet: 12.0, desktop: 13.0);

  // Border radius
  double get cardRadius =>
      responsiveValue(mobile: 8.0, tablet: 10.0, desktop: 12.0);

  double get buttonRadius =>
      responsiveValue(mobile: 8.0, tablet: 10.0, desktop: 12.0);

  // Font size helper
  double getResponsiveFontSize(double baseFontSize) {
    if (_isMobile) {
      return baseFontSize * 0.9;
    } else if (_isTablet) {
      return baseFontSize * 0.95;
    }
    return baseFontSize;
  }

  // Grid column count helper
  int getGridColumnCount({int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (_isMobile) return mobile;
    if (_isTablet) return tablet;
    return desktop;
  }

  // Sidebar visibility helper
  bool get shouldShowSidebar => !_isMobile;

  // AppBar height helper
  double get appBarHeight {
    if (_isMobile) return kToolbarHeight;
    return kToolbarHeight + 8;
  }

  // Card elevation helper
  double get cardElevation {
    if (_isMobile) return 2;
    return 4;
  }

  // Border radius helper
  double get borderRadius {
    if (_isMobile) return 8;
    return 12;
  }
}
