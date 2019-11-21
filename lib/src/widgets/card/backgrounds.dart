import 'package:flutter/material.dart';

class IrmaCardTheme {
  Color bgColorLight;
  Color bgColorDark;
  Color fgColor;

  IrmaCardTheme(this.bgColorLight, this.bgColorDark, this.fgColor);
}

final List<IrmaCardTheme> backgrounds = [
  IrmaCardTheme(const Color(0xff6CE6C1), const Color(0xff3BB992), const Color(0xff000000)),
  IrmaCardTheme(const Color(0xff43C3E0), const Color(0xff00B1E5), const Color(0xff000000)),
  IrmaCardTheme(const Color(0xffFFE8CD), const Color(0xffFFB54C), const Color(0xff000000)),
  IrmaCardTheme(const Color(0xff2574A6), const Color(0xff014483), const Color(0xffffffff)),
  IrmaCardTheme(const Color(0xffD3263B), const Color(0xffBD2D3B), const Color(0xffffffff)),
];
