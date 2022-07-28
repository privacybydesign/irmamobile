import 'package:flutter/material.dart';

Color? colorFromCode(String? colorCode) {
  if (colorCode == null || colorCode.length != 7 || colorCode[0] != '#') {
    return null;
  }

  final rgbInt = int.tryParse(colorCode.substring(1, 7), radix: 16);
  if (rgbInt == null) {
    return null;
  }

  return Color(0xFF000000 + rgbInt);
}
