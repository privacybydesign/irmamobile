import 'dart:ui';

Color? colorFromCode(String? colorCode) {
  if (colorCode == null || colorCode.length != 7 || colorCode[0] != '#') {
    return null;
  }

  final rgbInt = int.tryParse(colorCode.substring(1, 7), radix: 16);
  if (rgbInt == null) {
    return null;
  }

  const alphaInt = 0xFF000000;
  return Color(alphaInt + rgbInt);
}
