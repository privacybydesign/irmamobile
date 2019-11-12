import 'package:flutter/widgets.dart';

class Issuer {
  String name;
  Color color;
  Color backgroundColor;
  String backgroundImageFilename;

  Issuer({
    @required this.name,
    this.color,
    this.backgroundColor,
    this.backgroundImageFilename,
  }) : assert(name != null);
}
