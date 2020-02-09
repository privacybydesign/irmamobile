import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';

import 'card_attributes.dart';
import 'card_menu.dart';

class IrmaCard extends StatefulWidget {
  final String lang = ui.window.locale.languageCode;

  final Credential credential;
  final Function() onRefreshCredential;
  final Function() onDeleteCredential;

  final void Function(double) scrollBeyondBoundsCallback;
  final bool isDeleted;

  IrmaCard({
    this.credential,
    this.onRefreshCredential,
    this.onDeleteCredential,
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
  final irmaClient = IrmaRepository.get();

  // State
  bool isCardReadable = false;
  IrmaCardTheme cardTheme;
  Image photo;

  @override
  void initState() {
    cardTheme = calculateIrmaCardColor(widget.credential.issuer);
    photo = Image.memory(widget.credential.decodeImage());

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
              color: cardTheme.bgColorDark,
              gradient: LinearGradient(
                colors: [
                  cardTheme.bgColorDark,
                  cardTheme.bgColorLight,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                width: 1.0,
                color: cardTheme.bgColorLight,
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
                          getTranslation(widget.credential.credentialType.name),
                          style: Theme.of(context).textTheme.subhead.copyWith(
                                color: cardTheme.fgColor,
                              ),
                        ),
                      ),
                      CardMenu(
                        cardTheme: cardTheme,
                        onRefreshCredential: widget.onRefreshCredential,
                        onDeleteCredential: widget.onDeleteCredential,
                      )
                    ],
                  ),
                ),
                Container(
                  child: CardAttributes(
                    credential: widget.credential,
                    isCardUnblurred: isCardReadable,
                    irmaCardTheme: cardTheme,
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
