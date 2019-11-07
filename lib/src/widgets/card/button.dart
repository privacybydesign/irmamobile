import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class CardButton extends StatefulWidget {
  final String svgFile;
  final String accessibleName;
  final VoidCallback clickCallback;

  CardButton(this.svgFile, this.accessibleName, this.clickCallback);

  @override
  _CardButtonState createState() => _CardButtonState();
}

class _CardButtonState extends State<CardButton> with SingleTickerProviderStateMixin {
  AnimationController controller;

  static const padding = 15.0;

  bool buttonPressedState = false;
  Timer timer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, widget.accessibleName),
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.clickCallback();
          },
          child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (tapDownDetails) {
                setState(() {
                  buttonPressedState = true;
                });
              },
              onPointerUp: (tapUpDetails) {
                setState(() {
                  buttonPressedState = false;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(right: padding),
                child: SvgPicture.asset(widget.svgFile, color: buttonPressedState ? Colors.grey[700] : Colors.white),
              ))),
    );
  }
}
