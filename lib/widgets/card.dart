import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class AnimatedCard extends AnimatedWidget {
  static final _opacityTween = Tween<double>(begin: 0, end: 1);
  static final _heightTween = Tween<double>(begin: 240, end: 500);
  static final _rotateTween = Tween<double>(begin: 0, end: math.pi);

  static const indent = 100.0;
  static const headerBottom = 30.0;
  static const borderRadius = Radius.circular(15.0);
  static const padding = 15.0;
  static const transparentWhite = Color(0xaaffffff);

  List<Map<String, String>> personalData;
  bool isUnfolded = false;
  Animation<double> animation;
  Map<String, Object> issuer; // Object is String | Color

  AnimatedCard(
      {Key key,
      AnimationController controller,
      Animation<double> this.animation,
      this.personalData,
      this.issuer})
      : super(key: key, listenable: controller);

  @override
  Widget build(BuildContext context) {
    final AnimationController controller = listenable as AnimationController;

    List<Widget> getDataLines() {
      var textLines = <Widget>[
        Divider(color: transparentWhite),
      ];

      for (var i = 0; i < personalData.length; i++) {
        textLines.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  child: Text(personalData[i]['key'],
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                        color: issuer['color'],
                      )),
                  width: indent,
                ),
                Text(
                  personalData[i]['value'],
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: issuer['color'],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return textLines;
    }

    return Container(
      child: Column(
        children: <Widget>[
          Container(
            child: Padding(
              padding: EdgeInsets.only(
                  top: padding,
                  right: padding,
                  bottom: headerBottom,
                  left: indent),
              child: Text(
                "Persoonsgegevens",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: issuer['color'],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Opacity(
                  opacity: _opacityTween.evaluate(animation),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: getDataLines(),
                  )),
            ),
          ),
          Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: false,
                    label: 'Uitvouwen',
                    child: Transform(
                      origin: Offset(27, 24),
                      transform: Matrix4.rotationZ(
                        _rotateTween.evaluate(animation),
                      ),
                      child: IconButton(
                        icon: SvgPicture.asset('assets/icons/arrow-down.svg'),
                        padding: EdgeInsets.only(left: padding),
                        alignment: Alignment.centerLeft,
                        onPressed: () {
                          if (isUnfolded) {
                            controller.reverse();
                          } else {
                            controller.forward();
                          }
//                          setState(() {})
                          isUnfolded = !isUnfolded;
                        },
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Bijwerken',
                  child: Opacity(
                    opacity: _opacityTween.evaluate(animation),
                    child: IconButton(
                      icon: SvgPicture.asset('assets/icons/update.svg'),
                      padding: EdgeInsets.only(right: padding),
                      onPressed: () {
                        print('update');
                      },
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Verwijderen',
                  child: Opacity(
                    opacity: _opacityTween.evaluate(animation),
                    child: IconButton(
                      icon: SvgPicture.asset('assets/icons/delete.svg'),
                      padding: EdgeInsets.only(right: padding),
                      onPressed: () {
                        print('delete');
                      },
                    ),
                  ),
                ),
              ],
            ),
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: borderRadius,
                bottomRight: borderRadius,
              ),
            ),
          ),
        ],
      ),
      height: _heightTween.evaluate(animation),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: issuer['bg-color'],
          borderRadius: BorderRadius.all(
            borderRadius,
          ),
          image: DecorationImage(
              image: AssetImage("assets/issuers/${issuer['bg']}"),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter)),
    );
  }
}

class _IrmaCardState extends State<IrmaCard>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  static const animationDuration = 250;

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: animationDuration), vsync: this);

    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AnimatedCard(
        controller: controller,
        animation: animation,
        personalData: widget.personalData,
        issuer: widget.issuer,
      );
}

class IrmaCard extends StatefulWidget {
  List<Map<String, String>> personalData;
  Map<String, Object> issuer; // Object is String | Color

  IrmaCard(this.personalData, this.issuer);

  @override
  _IrmaCardState createState() => _IrmaCardState();
}
