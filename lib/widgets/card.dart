import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'button.dart';

class IrmaCard extends StatefulWidget {
  Map<String, List<Map<String, String>>> personalData;
  Map<String, Object> issuer; // Object is String | Color

  StreamController<bool> unfoldStream = StreamController();
  StreamController<void> updateStream = StreamController();
  StreamController<void> removeStream = StreamController();

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
  static const transparentWhiteLine = Color(0xaaffffff);
  static const transparentWhiteBackground = Color(0x55ffffff);

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
                    style: Style.heading1,
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
                              widget.unfoldStream.sink.add(isUnfolded);
                            },
                          ),
                        ),
                      ),
                    ),
                    Button(animation, 'assets/icons/update.svg',
                        'accessibility.update', widget.updateStream.sink),
                    Button(animation, 'assets/icons/remove.svg',
                        'accessibility.remove', widget.removeStream.sink)
                  ],
                ),
                height: 50,
                decoration: BoxDecoration(
                  color: transparentWhiteBackground,
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

  Map<String, List<Map<String, String>>> personalData;
  Map<String, Object> issuer; // Object is String | Color

  _personalData(this.personalData, this.issuer);

  Widget build(BuildContext context) {
    List<Widget> textLines = <Widget>[
      Divider(color: transparentWhite),
    ];

    textLines.addAll(personalData['data'].map((personal) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              child: Text(personal['key'], style: Style.light),
              width: indent,
            ),
            Text(
              personal['value'],
              style: Style.bold,
            ),
          ],
        ),
      );
    }));

    textLines.add(Divider(color: transparentWhite));

    textLines.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            child: Text('Uitgifte', style: Style.light),
            width: indent,
          ),
          Text(
            issuer['name'],
            style: Style.bold,
          ),
        ],
      ),
    ));

    textLines.addAll(personalData['metadata'].map((personal) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              child: Text(personal['key'], style: Style.light),
              width: indent,
            ),
            Text(
              personal['value'],
              style: Style.bold,
            ),
          ],
        ),
      );
    }));

    return ListView(
      children: textLines,
    );
  }
}

class Style {
  static const TextStyle heading1 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle bold = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle light = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w300,
    color: Colors.white,
  );
}
