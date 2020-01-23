import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/theme/theme.dart';

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

  @override
  void initState() {
    irmaCardTheme = calculateIrmaCardColor(widget.attributes.issuer);

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
                  child: Text(
                    getTranslation(widget.attributes.credentialType.name),
                    style: Theme.of(context).textTheme.subhead.copyWith(
                          color: irmaCardTheme.fgColor,
                        ),
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
          stackedCard: LayoutBuilder(
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
}

Widget stackedCard({Widget card, Widget stackedCard, bool applyStack}) => applyStack
    ? Stack(
        children: <Widget>[
          card,
          Positioned.fill(
            child: stackedCard,
          ),
        ],
      )
    : card;
