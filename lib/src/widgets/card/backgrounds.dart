import 'package:flutter/material.dart';

class IrmaCardTheme {
  String bgImage;
  Color bgColor;
  Color fgColor;

  IrmaCardTheme(this.bgImage, this.bgColor, this.fgColor);

  getBackgroundImage() {
    return AssetImage("assets/backgrounds/$bgImage");
  }
}

final backgrounds = [
  [
    IrmaCardTheme("darkblue1.png", Color(0xff004C92), Color(0xffffffff)),
    IrmaCardTheme("darkblue2.png", Color(0xff004C92), Color(0xffffffff)),
    IrmaCardTheme("darkblue3.png", Color(0xff004C92), Color(0xffffffff)),
    IrmaCardTheme("darkblue4.png", Color(0xff004C92), Color(0xffffffff)),
    IrmaCardTheme("darkblue5.png", Color(0xff004C92), Color(0xffffffff)),
  ],
  [
    IrmaCardTheme("green1.png", Color(0xff2BC194), Color(0xff000000)),
    IrmaCardTheme("green2.png", Color(0xff2BC194), Color(0xff000000)),
    IrmaCardTheme("green3.png", Color(0xff2BC194), Color(0xff000000)),
    IrmaCardTheme("green4.png", Color(0xff2BC194), Color(0xff000000)),
    IrmaCardTheme("green5.png", Color(0xff2BC194), Color(0xff000000)),
    IrmaCardTheme("green6.png", Color(0xff2BC194), Color(0xff000000)),
  ],
  [
    IrmaCardTheme("lightblue1.png", Color(0xff00B1E6), Color(0xff000000)),
    IrmaCardTheme("lightblue2.png", Color(0xff00B1E6), Color(0xff000000)),
    IrmaCardTheme("lightblue3.png", Color(0xff00B1E6), Color(0xff000000)),
    IrmaCardTheme("lightblue4.png", Color(0xff00B1E6), Color(0xff000000)),
    IrmaCardTheme("lightblue5.png", Color(0xff00B1E6), Color(0xff000000)),
    IrmaCardTheme("lightblue6.png", Color(0xff00B1E6), Color(0xff000000)),
  ],
  [
    IrmaCardTheme("orange1.png", Color(0xffFFBB58), Color(0xff000000)),
    IrmaCardTheme("orange2.png", Color(0xffFFBB58), Color(0xff000000)),
    IrmaCardTheme("orange3.png", Color(0xffFFBB58), Color(0xff000000)),
    IrmaCardTheme("orange4.png", Color(0xffFFBB58), Color(0xff000000)),
    IrmaCardTheme("orange5.png", Color(0xffFFBB58), Color(0xff000000)),
    IrmaCardTheme("orange6.png", Color(0xffFFBB58), Color(0xff000000)),
    IrmaCardTheme("orange7.png", Color(0xffFFBB58), Color(0xff000000)),
  ],
  [
    IrmaCardTheme("red1.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red2.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red3.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red4.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red5.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red6.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red7.png", Color(0xffD44454), Color(0xff000000)),
    IrmaCardTheme("red8.png", Color(0xffD44454), Color(0xff000000)),
  ]
];
