import 'package:flutter/material.dart';

Color colorFromCode(String? colorCode) {
  // TODO How mandatory is this field?
  // assert (colorCode == null || colorCode.length != 7 || colorCode[0] != '#');

  if (colorCode == null || colorCode.length != 7 || colorCode[0] != '#') {
    return Colors.transparent;
  }

  final rgbInt = int.tryParse(colorCode.substring(1, 7), radix: 16);
  if (rgbInt == null) {
    return Colors.transparent;
  }

  const alphaInt = 0xFF000000;
  return Color(alphaInt + rgbInt);
}
