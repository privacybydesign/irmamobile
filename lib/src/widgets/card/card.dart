import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/card/button.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/card-attributes.dart';

class IrmaCard extends StatefulWidget {
  final String lang = ui.window.locale.languageCode;

  final Credential attributes;
  final bool isOpen;
  final VoidCallback updateCallback;
  final VoidCallback removeCallback;
  final void Function(double) scrollOverflowCallback;

  IrmaCard({this.attributes, this.isOpen, this.updateCallback, this.removeCallback, this.scrollOverflowCallback});

  @override
  _IrmaCardState createState() => _IrmaCardState();
}

class _IrmaCardState extends State<IrmaCard> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  final _opacityTween = Tween<double>(begin: 0, end: 1);
  final _rotateTween = Tween<double>(begin: 0, end: math.pi);

  final _animationDuration = 250;
  final _headerBottom = 30.0;
  final _borderRadius = Radius.circular(15.0);
  final _padding = 15.0;
  final _transparentWhiteBackground = Color(0x55ffffff);

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

  IrmaCardTheme calculateIrmaCardTheme(Issuer issuer) {
    final int strNum = issuer.id.runes.reduce((oldChar, newChar) {
      return (oldChar << 2) ^ newChar;
    });

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
      builder: (buildContext, child) {
        return GestureDetector(
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
              color: irmaCardTheme.bgColorLight,
              gradient: LinearGradient(
                colors: [irmaCardTheme.bgColorLight, irmaCardTheme.bgColorDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
              ),
              borderRadius: BorderRadius.all(
                _borderRadius,
              ),
            ),
            child: Column(
              children: <Widget>[
                Container(
                  child: Padding(
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
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_padding),
                    child: Opacity(
                        opacity: _opacityTween.evaluate(animation),
                        child: _opacityTween.evaluate(animation) == 0
                            ? const Text("")
                            : CardAttributes(widget.attributes, widget.attributes.issuer, isCardReadable, widget.lang,
                                irmaCardTheme, widget.scrollOverflowCallback)),
                  ),
                ),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _transparentWhiteBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: _borderRadius,
                      bottomRight: _borderRadius,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Semantics(
                          button: true,
                          enabled: false,
                          label: FlutterI18n.translate(context, 'accessibility.unfold'),
                          child: Transform(
                            origin: const Offset(27, 24),
                            transform: Matrix4.rotationZ(
                              _rotateTween.evaluate(animation),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: SvgPicture.asset('assets/icons/arrow-down.svg'),
                              padding: EdgeInsets.only(left: _padding),
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                          opacity: _opacityTween.evaluate(animation),
                          child: CardButton('assets/icons/update.svg', 'accessibility.update', widget.updateCallback)),
                      Opacity(
                          opacity: _opacityTween.evaluate(animation),
                          child: CardButton('assets/icons/remove.svg', 'accessibility.remove', widget.removeCallback))
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
}
