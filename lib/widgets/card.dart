import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class IrmaCard extends StatefulWidget {
  List<Map<String, String>> personalData;
  Map<String, Object> issuer; // Object is String | Color

  IrmaCard(this.personalData, this.issuer);

  @override
  _IrmaCardState createState() => _IrmaCardState();
}

class _IrmaCardState extends State<IrmaCard>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  static final _opacityTween = Tween<double>(begin: 0, end: 1);
  static final _heightTween = Tween<double>(begin: 240, end: 500);
  static final _rotateTween = Tween<double>(begin: 0, end: math.pi);

  static const animationDuration = 250;
  static const indent = 100.0;
  static const headerBottom = 30.0;
  static const borderRadius = Radius.circular(15.0);
  static const padding = 15.0;
  static const transparentWhite = Color(0xaaffffff);

  // State
  bool isUnfolded = false;

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: animationDuration), vsync: this);

    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (buildContext, child) {
        return Container(
          child: Column(
            children: <Widget>[
              Container(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: padding,
                    right: padding,
                    bottom: headerBottom,
                  ),
                  child: Text(
                    FlutterI18n.translate(context, 'card.personaldata'),
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: widget.issuer['color'],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(padding),
                  child: Opacity(
                      opacity: _opacityTween.evaluate(animation),
                      child: _personalData(widget.personalData, widget.issuer)),
                ),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Semantics(
                        button: true,
                        enabled: false,
                        label: FlutterI18n.translate(
                            context, 'accessibility.unfold'),
                        child: Transform(
                          origin: Offset(27, 24),
                          transform: Matrix4.rotationZ(
                            _rotateTween.evaluate(animation),
                          ),
                          child: IconButton(
                            icon:
                                SvgPicture.asset('assets/icons/arrow-down.svg'),
                            padding: EdgeInsets.only(left: padding),
                            alignment: Alignment.centerLeft,
                            onPressed: () {
                              if (isUnfolded) {
                                controller.reverse();
                              } else {
                                controller.forward();
                              }
                              setState(() {
                                isUnfolded = !isUnfolded;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: FlutterI18n.translate(
                          context, 'accessibility.update'),
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
                      label: FlutterI18n.translate(
                          context, 'accessibility.remove'),
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
              color: widget.issuer['bg-color'],
              borderRadius: BorderRadius.all(
                borderRadius,
              ),
              image: DecorationImage(
                  image: AssetImage("assets/issuers/${widget.issuer['bg']}"),
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter)),
        );
      });
}

class _personalData extends StatelessWidget {
  static const transparentWhite = Color(0xaaffffff);
  static const indent = 100.0;

  List<Map<String, String>> personalData;
  Map<String, Object> issuer; // Object is String | Color

  _personalData(this.personalData, this.issuer);

  Widget build(BuildContext context) {
    List<Widget> textLines = <Widget>[
      Divider(color: transparentWhite),
    ];

    textLines.addAll(personalData.map((personal) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              child: Text(personal['key'],
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w300,
                    color: issuer['color'],
                  )),
              width: indent,
            ),
            Text(
              personal['value'],
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: issuer['color'],
              ),
            ),
          ],
        ),
      );
    }));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: textLines,
    );
  }
}
