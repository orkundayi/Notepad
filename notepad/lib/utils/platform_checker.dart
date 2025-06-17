import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformChecker {
  static bool get isWindowsDesktop => !kIsWeb && Platform.isWindows;

  static bool get isMobileOrWeb =>
      kIsWeb || Platform.isAndroid || Platform.isIOS;

  static bool get supportsFirebaseAuth =>
      kIsWeb || Platform.isAndroid || Platform.isIOS;
}
