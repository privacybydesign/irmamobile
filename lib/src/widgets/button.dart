import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Button extends StatefulWidget {
  final Animation<double> animation;
  final String svgFile;
  final String accessibleName;
  final Function() onPressed;

  Button({this.animation, this.svgFile, this.accessibleName, this.onPressed});

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> with SingleTickerProviderStateMixin {
  AnimationController controller;

  final _opacityTween = Tween<double>(begin: 0, end: 1);
  final _padding = 15.0;

  bool _isBeingPressed = false;
  Timer _timer;

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
              icon: SvgPicture.asset(widget.svgFile, color: _isBeingPressed ? Colors.grey[700] : Colors.white),
              padding: EdgeInsets.only(right: _padding),
              onPressed: () {
                widget.onPressed();
                setState(() {
                  _isBeingPressed = true;
                });
                if (_timer != null) {
                  _timer.cancel();
                }
                _timer = Timer(Duration(milliseconds: 200), () {
                  setState(() {
                    _isBeingPressed = false;
                  });
                });
              },
            ),
          ),
        );
      });
}
