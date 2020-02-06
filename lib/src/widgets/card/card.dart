import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';

import 'card_attributes.dart';

class IrmaCard extends StatefulWidget {
  final String lang = ui.window.locale.languageCode;

  final Credential attributes;
  final void Function(double) scrollBeyondBoundsCallback;
  final bool isDeleted;

  IrmaCard({
    this.attributes,
    this.scrollBeyondBoundsCallback,
    this.isDeleted = false,
  });

  @override
  _IrmaCardState createState() => _IrmaCardState();
}

class _IrmaCardState extends State<IrmaCard> with SingleTickerProviderStateMixin {
  final _borderRadius = const Radius.circular(15.0);
  final _transparentWhite = const Color(0x77FFFFFF);
  final _transparentBlack = const Color(0x77000000);
  final _blurRadius = 4.0;

  // State
  bool isCardReadable = false;
  IrmaCardTheme irmaCardTheme;
  Image photo;

  @override
  void initState() {
    irmaCardTheme = calculateIrmaCardColor(widget.attributes.issuer);
    photo = Image.memory(widget.attributes.decodeImage());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
      child: stackedCard(
          card: Container(
            margin: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
            decoration: BoxDecoration(
              color: irmaCardTheme.bgColorDark,
              gradient: LinearGradient(
                colors: [
                  irmaCardTheme.bgColorDark,
                  irmaCardTheme.bgColorLight,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                width: 1.0,
                color: irmaCardTheme.bgColorLight,
              ),
              borderRadius: BorderRadius.all(
                _borderRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: _transparentBlack,
                  blurRadius: _blurRadius,
                  offset: const Offset(
                    0.0,
                    2.0,
                  ),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                    top: IrmaTheme.of(context).smallSpacing,
                    left: IrmaTheme.of(context).defaultSpacing,
                    bottom: 0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          getTranslation(widget.attributes.credentialType.name),
                          style: Theme.of(context).textTheme.subhead.copyWith(
                                color: irmaCardTheme.fgColor,
                              ),
                        ),
                      ),
                      _offsetPopup(),
                    ],
                  ),
                ),
                Container(
                  child: CardAttributes(
                    personalData: widget.attributes,
                    issuer: widget.attributes.issuer,
                    isCardUnblurred: isCardReadable,
                    irmaCardTheme: irmaCardTheme,
                    scrollOverflowCallback: widget.scrollBeyondBoundsCallback,
                  ),
                ),
              ],
            ),
          ),
          getStackedCard: () => LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height: constraints.smallest.height,
                      margin: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                      decoration: BoxDecoration(
                        color: _transparentWhite,
                        borderRadius: BorderRadius.all(
                          _borderRadius,
                        ),
                      ),
                    ),
                  );
                },
              ),
          applyStack: widget.isDeleted),
    );
  }

  // Calculate a card color dependent of the issuer id
  //
  // This is to prevent all cards getting a different
  // color when a card is added or removed and confusing
  // the user.
  IrmaCardTheme calculateIrmaCardColor(Issuer issuer) {
    final int strNum = issuer.id.runes.reduce((oldChar, newChar) => (oldChar << 1) ^ newChar);

    return backgrounds[strNum % backgrounds.length];
  }

  Widget _offsetPopup() => PopupMenuButton<int>(
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 1,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.refresh,
                    color: IrmaTheme.of(context).primaryDark,
                  ),
                ),
                Text(
                  FlutterI18n.translate(context, 'card.refresh'),
                  style: IrmaTheme.of(context).textTheme.subtitle.copyWith(color: IrmaTheme.of(context).primaryDark),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.delete,
                    color: IrmaTheme.of(context).primaryDark,
                  ),
                ),
                Text(
                  FlutterI18n.translate(context, 'card.delete'),
                  style: IrmaTheme.of(context).textTheme.subtitle.copyWith(color: IrmaTheme.of(context).primaryDark),
                ),
              ],
            ),
          ),
        ],
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        color: IrmaTheme.of(context).primaryLight,
        child: Transform.rotate(
          // TODO replace icon in iconfont to a horizontalNav and remove this rotate
          angle: 90 * math.pi / 180,
          child: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(IrmaIcons.verticalNav, size: 22.0, color: IrmaTheme.of(context).primaryDark),
              )),
        ),
      );

  Widget stackedCard({Widget card, Widget Function() getStackedCard, bool applyStack}) => applyStack
      ? Stack(
          children: <Widget>[
            card,
            Positioned.fill(
              child: stackedCard(),
            ),
          ],
        )
      : card;
}
