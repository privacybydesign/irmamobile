import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

@immutable
class WalletButton extends StatefulWidget {
  final String svgFile;
  final String accessibleName;
  final VoidCallback clickStreamSink;

  const WalletButton({this.svgFile, this.accessibleName, this.clickStreamSink});

  @override
  _WalletButtonState createState() => _WalletButtonState();
}

class _WalletButtonState extends State<WalletButton> with SingleTickerProviderStateMixin {
  AnimationController controller;

  static const padding = 8.0;

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
          widget.clickStreamSink();
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
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xfff6f8fc),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: SvgPicture.asset(
                widget.svgFile,
                color: buttonPressedState ? IrmaThemeData().primaryBlue : IrmaThemeData().overlay50,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
