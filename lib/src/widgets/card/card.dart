import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/card_attributes.dart';

class IrmaCard extends StatefulWidget {
  final String lang = ui.window.locale.languageCode;

  final Credential attributes;
  final bool isOpen;
  final void Function(double) scrollOverflowCallback;

  IrmaCard({this.attributes, this.isOpen, this.scrollOverflowCallback});

  @override
  _IrmaCardState createState() => _IrmaCardState();
}

class _IrmaCardState extends State<IrmaCard> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  final _opacityTween = Tween<double>(begin: 0, end: 1);

  final _animationDuration = 250;
  final _headerBottom = 30.0;
  final _borderRadius = const Radius.circular(15.0);
  final _padding = 15.0;

  var _heightTween = Tween<double>(begin: 240, end: 400);

  // State
  bool isUnfolded = false;
  bool isCardReadable = false;

  IrmaCardTheme irmaCardTheme;

  @override
  void initState() {
    controller = AnimationController(duration: Duration(milliseconds: _animationDuration), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    irmaCardTheme = calculateIrmaCardTheme(widget.attributes.issuer);

    super.initState();
  }

  @override
  void didUpdateWidget(IrmaCard oldWidget) {
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        open(height: 400);
      } else {
        close();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  // Calculate a card color dependent of the issuer id
  //
  // This is to prevent all cards getting a different
  // color when a card is added or removed and confusing
  // the user.
  IrmaCardTheme calculateIrmaCardTheme(Issuer issuer) {
    final int strNum = issuer.id.runes.reduce((oldChar, newChar) => (oldChar << 1) ^ newChar);

    return backgrounds[strNum % backgrounds.length];
  }

  void open({double height}) {
    _heightTween = Tween<double>(begin: 240, end: height);
    controller.forward();
    setState(() {
      isUnfolded = true;
    });
  }

  void close() {
    controller.reverse();
    setState(() {
      isUnfolded = false;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (buildContext, child) => GestureDetector(
          onLongPress: () {
            setState(() {
              isCardReadable = true;
            });
          },
          onLongPressUp: () {
            setState(() {
              isCardReadable = false;
            });
          },
          child: Container(
            height: _heightTween.evaluate(animation),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: irmaCardTheme.bgColorDark,
              gradient: LinearGradient(
                  colors: [irmaCardTheme.bgColorDark, irmaCardTheme.bgColorLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              border: Border.all(width: 1.0, color: irmaCardTheme.bgColorLight),
              borderRadius: BorderRadius.all(
                _borderRadius,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 4.0,
                  offset: Offset(
                    0.0,
                    2.0,
                  ),
                )
              ],
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                    top: _padding,
                    right: _padding,
                    bottom: _headerBottom,
                  ),
                  child: Text(
                    FlutterI18n.translate(context, 'card.personaldata'),
                    style: Theme.of(context).textTheme.headline.copyWith(color: irmaCardTheme.fgColor),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_padding),
                    child: Opacity(
                        opacity: _opacityTween.evaluate(animation),
                        child: _opacityTween.evaluate(animation) == 0
                            ? const Text("")
                            : CardAttributes(
                                personalData: widget.attributes,
                                issuer: widget.attributes.issuer,
                                isCardUnblurred: isCardReadable,
                                lang: widget.lang,
                                irmaCardTheme: irmaCardTheme,
                                scrollOverflowCallback: widget.scrollOverflowCallback)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
