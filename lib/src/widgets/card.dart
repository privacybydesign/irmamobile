import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/button.dart';

class CardStyle {
  static final defaultStyles = [
    [
      CardStyle("darkblue1.png", Color(0xff777777), Color(0xffffffff)),
      CardStyle("darkblue2.png", Color(0xff777777), Color(0xffffffff)),
      CardStyle("darkblue3.png", Color(0xff777777), Color(0xffffffff)),
      CardStyle("darkblue4.png", Color(0xff777777), Color(0xffffffff)),
      CardStyle("darkblue5.png", Color(0xff777777), Color(0xffffffff)),
    ],
    [
      CardStyle("green1.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("green2.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("green3.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("green4.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("green5.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("green6.png", Color(0xff777777), Color(0xff000000)),
    ],
    [
      CardStyle("lightblue1.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("lightblue2.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("lightblue3.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("lightblue4.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("lightblue5.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("lightblue6.png", Color(0xff777777), Color(0xff000000)),
    ],
    [
      CardStyle("orange1.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("orange2.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("orange3.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("orange4.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("orange5.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("orange6.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("orange7.png", Color(0xff777777), Color(0xff000000)),
    ],
    [
      CardStyle("red1.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red2.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red3.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red4.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red5.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red6.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red7.png", Color(0xff777777), Color(0xff000000)),
      CardStyle("red8.png", Color(0xff777777), Color(0xff000000)),
    ]
  ];

  String _bgImagePath;
  Color bgColor;
  Color fgColor;

  CardStyle(this._bgImagePath, this.bgColor, this.fgColor);

  getBackgroundImage() {
    return AssetImage("assets/backgrounds/$_bgImagePath");
  }
}

class IrmaCard extends StatefulWidget {
  final RichCredential credential;
  final Function() onRefresh;
  final Function() onRemove;

  IrmaCard({this.credential, this.onRefresh, this.onRemove});

  @override
  _IrmaCardState createState() => _IrmaCardState();
}

class _IrmaCardState extends State<IrmaCard> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  final _opacityTween = Tween<double>(begin: 0, end: 1);
  final _rotateTween = Tween<double>(begin: 0, end: math.pi);

  final animationDuration = 250;
  final indent = 100.0;
  final headerBottom = 30.0;
  final borderRadius = Radius.circular(15.0);
  final padding = 15.0;
  final transparentWhiteLine = Color(0xaaffffff);
  final transparentWhiteBackground = Color(0x55ffffff);

  Tween<double> _heightTween = Tween<double>(begin: 240, end: 400);

  // State
  bool isUnfolded = false;

  @override
  void initState() {
    controller = AnimationController(duration: Duration(milliseconds: animationDuration), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    super.initState();
  }

  // TODO: Cache the style and adjust the calculation based on credential name
  CardStyle get _cardStyle {
    int strNum = widget.credential.credentialType.name['nl'].runes.reduce((oldChar, newChar) {
      return oldChar ^ newChar;
    });

    List<CardStyle> cardStyleSection = CardStyle.defaultStyles[strNum % CardStyle.defaultStyles.length];
    return cardStyleSection[(strNum ~/ CardStyle.defaultStyles.length) % cardStyleSection.length];
  }

  open({double height}) {
    // _heightTween = Tween<double>(begin: 240, end: height);
    controller.forward();
    setState(() {
      isUnfolded = true;
    });
  }

  close() {
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
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isUnfolded)
                close();
              else
                open();
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
                        style: Theme.of(context).textTheme.headline.copyWith(color: _cardStyle.fgColor),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Opacity(
                          opacity: _opacityTween.evaluate(animation),
                          child: _opacityTween.evaluate(animation) == 0
                              ? Text("")
                              : _PersonalData(credential: widget.credential, cardStyle: _cardStyle)),
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
                                  onPressed: () => {}),
                            ),
                          ),
                        ),
                        Opacity(
                            opacity: _opacityTween.evaluate(animation),
                            child: Button(
                                svgFile: 'assets/icons/refresh.svg',
                                accessibleName: 'accessibility.refresh',
                                onPressed: widget.onRefresh)),
                        Opacity(
                            opacity: _opacityTween.evaluate(animation),
                            child: Button(
                                svgFile: 'assets/icons/remove.svg',
                                accessibleName: 'accessibility.remove',
                                onPressed: widget.onRemove))
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
                  color: _cardStyle.bgColor,
                  borderRadius: BorderRadius.all(
                    borderRadius,
                  ),
                  image: DecorationImage(
                      image: _cardStyle.getBackgroundImage(), fit: BoxFit.fitWidth, alignment: Alignment.topCenter)),
            ));
      });
}

class _PersonalData extends StatelessWidget {
  static const transparentWhite = Color(0xaaffffff);
  static const indent = 100.0;

  final RichCredential credential;
  final CardStyle cardStyle;

  _PersonalData({this.credential, this.cardStyle});

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
                    style: Theme.of(context).textTheme.body1.copyWith(color: cardStyle.fgColor)),
                width: indent,
              ),
              _BlurText(attribute.value['nl'], cardStyle.fgColor, false),
            ],
          ),
        )));

    textLines.add(Divider(color: transparentWhite));

    textLines.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            child: Text('Uitgever', style: Theme.of(context).textTheme.body1.copyWith(color: cardStyle.fgColor)),
            width: indent,
          ),
          Text(
            credential.issuer.name['nl'],
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontWeight: FontWeight.w700)
                .copyWith(color: cardStyle.fgColor),
          ),
        ],
      ),
    ));

    textLines.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            child: Text(FlutterI18n.translate(context, 'card.expiresAt'),
                style: Theme.of(context).textTheme.body1.copyWith(color: cardStyle.fgColor)),
            width: indent,
          ),
          Text(
            credential.expires.toString(),
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontWeight: FontWeight.w700)
                .copyWith(color: cardStyle.fgColor),
          ),
        ],
      ),
    ));

    return Scrollbar(
        child: ListView(
      children: textLines,
    ));
  }
}

class _BlurText extends StatelessWidget {
  final String text;
  final Color color;
  final bool isTextBlurred;

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
