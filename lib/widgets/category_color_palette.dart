import 'package:flutter/material.dart';

class CategoryColorPalette {
  static const List<Color> colors = [
    Color(0xFFFFC8DD),
    Color(0xFFFFE5D9),
    Color(0xFFFFF1C1),
    Color(0xFFD9F7E8),
    Color(0xFFCDEBFF),
    Color(0xFFD7D4FF),
    Color(0xFFFFD6A5),
    Color(0xFFBDE0FE),
    Color(0xFFCFFFD1),
    Color(0xFFFFE0E0),
    Color(0xFFE6CCFF),
    Color(0xFFFFF5BA),
    Color(0xFFE2F0CB),
    Color(0xFFFDE2E4),
    Color(0xFFF0EFEB),
    Color(0xFFD6E2E9),
    Color(0xFFF6EAC2),
    Color(0xFFE3D7FF),
  ];

  static Color resolve(int? index) {
    if (index == null) {
      return colors[0];
    }
    final safeIndex = index % colors.length;
    return colors[safeIndex];
  }

  static int fallbackIndex(String seed) {
    var hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = (hash + codeUnit) % colors.length;
    }
    return hash;
  }
}
