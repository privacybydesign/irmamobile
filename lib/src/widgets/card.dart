import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/button.dart';

const tempColor = Colors.white;
const tempBgColor = Color(0xffec0000);

class IrmaCard extends StatefulWidget {
  final RichCredential credential;

  IrmaCard({this.credential});

  @override
  _IrmaCardState createState() => _IrmaCardState();
}

class _IrmaCardState extends State<IrmaCard> with SingleTickerProviderStateMixin {
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
  bool isCardReadable = false;

  @override
  void initState() {
    controller = AnimationController(duration: const Duration(milliseconds: animationDuration), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (buildContext, child) {
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isUnfolded) {
                controller.reverse();
              } else {
                controller.forward();
              }
              setState(() {
                isUnfolded = !isUnfolded;
              });
            },
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
                        widget.credential.credentialType.name['nl'],
                        style: Theme.of(context).textTheme.headline.copyWith(color: tempColor),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(padding),
                      child: Opacity(
                          opacity: _opacityTween.evaluate(animation),
                          child: _personalData(widget.credential, isCardReadable)),
                    ),
                  ),
                  Container(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Semantics(
                            button: true,
                            enabled: false,
                            label: FlutterI18n.translate(context, 'accessibility.unfold'),
                            child: Transform(
                              origin: Offset(27, 24),
                              transform: Matrix4.rotationZ(
                                _rotateTween.evaluate(animation),
                              ),
                              child: IconButton(
                                icon: SvgPicture.asset('assets/icons/arrow-down.svg'),
                                padding: EdgeInsets.only(left: padding),
                                alignment: Alignment.centerLeft,
                                /*onPressed: () => null,*/
                              ),
                            ),
                          ),
                        ),
                        Button(
                            animation: animation,
                            svgFile: 'assets/icons/refresh.svg',
                            accessibleName: 'accessibility.refresh',
                            onPressed: () => null),
                        Button(
                            animation: animation,
                            svgFile: 'assets/icons/remove.svg',
                            accessibleName: 'accessibility.remove',
                            onPressed: () => null)
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
                  color: tempBgColor,
                  borderRadius: BorderRadius.all(
                    borderRadius,
                  ),
                  image: DecorationImage(
                      image: AssetImage("assets/issuers/amsterdam.png"),
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter)),
            ));
      });
}

class _personalData extends StatelessWidget {
  static const transparentWhite = Color(0xaaffffff);
  static const indent = 100.0;

  final RichCredential credential;
  bool isCardUnblurred;

  _personalData(this.credential, this.isCardUnblurred);

  Widget build(BuildContext context) {
    List<Widget> textLines = <Widget>[
      Divider(color: transparentWhite),
    ];

    textLines.addAll(credential.attributes.map((attribute) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                child: Text(attribute.type.name['nl'],
                    style: Theme.of(context).textTheme.body1.copyWith(color: tempColor)),
                width: indent,
              ),
              _BlurText(attribute.value['nl'], tempColor, false && !isCardUnblurred),
            ],
          ),
        )));

    textLines.add(Divider(color: transparentWhite));

    textLines.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            child: Text('Uitgifte', style: Theme.of(context).textTheme.body1.copyWith(color: tempColor)),
            width: indent,
          ),
          Text(
            credential.issuer.name['nl'],
            style: Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.w700).copyWith(color: tempColor),
          ),
        ],
      ),
    ));

    textLines.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            child: Text("Geldig tot", style: Theme.of(context).textTheme.body1.copyWith(color: tempColor)),
            width: indent,
          ),
          Text(
            credential.expires.toString(),
            style: Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.w700).copyWith(color: tempColor),
          ),
        ],
      ),
    ));

    return ListView(
      children: textLines,
    );
  }
}

class _BlurText extends StatelessWidget {
  String text;
  Color color;
  bool isTextBlurred;

  _BlurText(this.text, this.color, this.isTextBlurred);

  Widget build(BuildContext context) {
    return isTextBlurred
        ? Opacity(
            opacity: 0.8,
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .body1
                  .copyWith(fontWeight: FontWeight.w700)
                  .copyWith(color: Color(0x00ffffff))
                  .copyWith(shadows: [
                Shadow(
                  blurRadius: 7.0,
                  color: color,
                ),
                Shadow(
                  blurRadius: 15.0,
                  color: color,
                ),
                Shadow(
                  blurRadius: 20.0,
                  color: color,
                ),
              ]),
            ),
          )
        : Text(text,
            style: Theme.of(context).textTheme.body1.copyWith(fontWeight: FontWeight.w700).copyWith(color: color));
  }
}
