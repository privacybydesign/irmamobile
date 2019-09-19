import 'package:flutter/widgets.dart';

class Issuer {
  String name;
  Color color;
  Color backgroundColor;
  String backgroundImageFilename;

  Issuer({this.name, this.color, this.backgroundColor, this.backgroundImageFilename}) : assert(name != null);
}
