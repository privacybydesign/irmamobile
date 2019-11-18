import 'package:flutter/material.dart';

class IrmaCardTheme {
  Color bgColorLight;
  Color fgColor;

  IrmaCardTheme({this.bgColorLight, this.fgColor});
}

final List<IrmaCardTheme> backgrounds = [
  IrmaCardTheme(bgColorLight: const Color(0xff004C92), fgColor: const Color(0xffffffff)),
  IrmaCardTheme(bgColorLight: const Color(0xff2BC194), fgColor: const Color(0xff000000)),
  IrmaCardTheme(bgColorLight: const Color(0xff00B1E6), fgColor: const Color(0xff000000)),
  IrmaCardTheme(bgColorLight: const Color(0xffFFBB58), fgColor: const Color(0xff000000)),
  IrmaCardTheme(bgColorLight: const Color(0xffD44454), fgColor: const Color(0xff000000)),
];
