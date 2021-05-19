import 'package:flutter/material.dart';

Color getColorFromHex(String hexColor) {
  var hex = hexColor.toUpperCase().replaceAll("#", "");
  if (hex.length != 6 && hex.length != 8) throw Exception("color string has incorrect length");
  if (hex.length == 6) {
    hex = "FF$hex";
  }
  return Color(int.parse(hex, radix: 16));
}
