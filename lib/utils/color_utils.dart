import 'dart:ui';

import 'package:my_grocery_list/utils/constants.dart';

class ColorUtils {
  ColorUtils._();

  /// Convert hex string to Color
  static Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Get color for family member by index
  static String getColorByIndex(int index) {
    return AppConstants.familyColors[index % AppConstants.familyColors.length];
  }
}
