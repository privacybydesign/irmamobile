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

  static const personalData = [
    {'key': 'Naam', 'value': 'Anouk Meijer'},
    {'key': 'Geboren', 'value': '4 juli 1990'},
    {'key': 'E-mail', 'value': 'anouk.meijer@gmail.com'},
  ];

  bool isUnfolded = false;

  Animation<double> _animation;

  AnimatedCard(
      {Key key, AnimationController controller, Animation<double> animation})
      : _animation = animation,
        super(key: key, listenable: controller);

  @override
  Widget build(BuildContext context) {
    final AnimationController controller = listenable as AnimationController;

    List<Widget> getDataLines() {
      var textLines = <Widget>[
        Divider(color: Color(0xaaffffff)),
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
                        color: Colors.white,
                      )),
                  width: indent,
                ),
                Text(
                  personalData[i]['value'],
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Opacity(
                  opacity: _opacityTween.evaluate(_animation),
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
                        _rotateTween.evaluate(_animation),
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
                    opacity: _opacityTween.evaluate(_animation),
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
                    opacity: _opacityTween.evaluate(_animation),
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
              color: Color(0x55ffffff),
              borderRadius: BorderRadius.only(
                bottomLeft: borderRadius,
                bottomRight: borderRadius,
              ),
            ),
          ),
        ],
      ),
      height: _heightTween.evaluate(_animation),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: Color(0xffec0000),
          borderRadius: BorderRadius.all(
            borderRadius,
          ),
          image: DecorationImage(
              image: AssetImage('assets/issuers/amsterdam/bg.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter)),
    );
  }
}

class IrmaCardState extends State<IrmaCard>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  static const animationDuration = 250;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: animationDuration), vsync: this);

    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) => AnimatedCard(
        controller: controller,
        animation: animation,
      );
}

class IrmaCard extends StatefulWidget {
  @override
  IrmaCardState createState() => IrmaCardState();
}
