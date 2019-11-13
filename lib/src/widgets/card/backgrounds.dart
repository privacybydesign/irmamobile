import 'package:flutter/material.dart';

class IrmaCardTheme {
  Color bgColorLight;
  Color fgColor;

  IrmaCardTheme(this.bgColorLight, this.fgColor);
}

final List<IrmaCardTheme> backgrounds = [
    IrmaCardTheme(const Color(0xff004C92), const Color(0xffffffff)),
    IrmaCardTheme(const Color(0xff2BC194), const Color(0xff000000)),
    IrmaCardTheme(const Color(0xff00B1E6), const Color(0xff000000)),
    IrmaCardTheme(const Color(0xffFFBB58), const Color(0xff000000)),
    IrmaCardTheme(const Color(0xffD44454), const Color(0xff000000)),
];
