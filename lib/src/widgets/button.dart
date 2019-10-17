import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class Button extends StatefulWidget {
  Animation<double> animation;
  IconData iconData;
  String accessibleName;
  StreamSink clickStreamSink;

  Button(this.animation, this.iconData, this.accessibleName, this.clickStreamSink);

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> with SingleTickerProviderStateMixin {
  AnimationController controller;

  static final _opacityTween = Tween<double>(begin: 0, end: 1);
  static const padding = 15.0;

  bool buttonPressedState = false;
  Timer timer = null;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.animation,
      builder: (buildContext, child) {
        return Semantics(
          button: true,
          label: FlutterI18n.translate(context, widget.accessibleName),
          child: Opacity(
            opacity: _opacityTween.evaluate(widget.animation),
            child: IconButton(
              icon: Icon(widget.iconData, color: buttonPressedState ? Colors.grey[700] : Colors.white),
              padding: EdgeInsets.only(right: padding),
              onPressed: () {
                widget.clickStreamSink.add(true);
                setState(() {
                  buttonPressedState = true;
                });
                if (timer != null) {
                  timer.cancel();
                }
                timer = Timer(Duration(milliseconds: 200), () {
                  setState(() {
                    buttonPressedState = false;
                  });
                });
              },
            ),
          ),
        );
      });
}
