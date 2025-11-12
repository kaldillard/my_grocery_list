import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformService {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  static String getCheckoutUrl(String tier, String familyId) {
    // Your web app URL
    return 'https://yourdomain.com/checkout?tier=$tier&family=$familyId';
  }
}
