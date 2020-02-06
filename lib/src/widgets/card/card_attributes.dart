import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/blurtext.dart';

class CardAttributes extends StatelessWidget {
  final _lang = ui.window.locale.languageCode;
  final _indent = 100.0;
  final _maxHeight = 300.0;
  final _minHeight = 120.0; // TODO: perfect aspect ratio

  final Credential personalData;
  final Issuer issuer;
  final bool isCardUnblurred;
  final IrmaCardTheme irmaCardTheme;
  final Image photo;
  final void Function(double) scrollOverflowCallback;

  CardAttributes(
      {this.personalData,
      this.issuer,
      this.isCardUnblurred,
      this.irmaCardTheme,
      this.photo,
      this.scrollOverflowCallback});

  @override
  Widget build(BuildContext context) {
    final TextStyle bodyTheme = IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor);

    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.offset < 0) {
        scrollOverflowCallback(-scrollController.offset);
      }
    });

    return Column(
      children: [
        LimitedBox(
          maxHeight: _maxHeight,
          child: Container(
            padding: EdgeInsets.only(
              top: IrmaTheme.of(context).defaultSpacing,
              left: IrmaTheme.of(context).defaultSpacing,
              right: IrmaTheme.of(context).smallSpacing,
            ),
            constraints: BoxConstraints(
              minHeight: _minHeight,
            ),
            child: photoCard(
              card: Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(left: IrmaTheme.of(context).defaultSpacing),
                  children: [
                    ...getAttributes(context, bodyTheme),
                    SizedBox(
                      height: IrmaTheme.of(context).defaultSpacing,
                    ),
                  ],
                ),
              ),
              photoCard: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 90,
                  height: 120,
                  color: const Color(0xff777777),
                  child: photo,
                ),
              ),
              applyPhoto: photo != null,
            ),
          ),
        ),
        Column(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1.0, color: Color(0x77000000)),
                  bottom: BorderSide(width: 1.0, color: Color(0x77FFFFFF)),
                ),
              ),
            ),
            Container(
              color: const Color(0x11FFFFFF),
              child: Column(
                children: <Widget>[getIssuer(context, bodyTheme), getExpiration(context, bodyTheme)],
              ),
            )
          ],
        ),
      ],
    );
  }

  List<Widget> getAttributes(BuildContext context, TextStyle bodyTheme) => personalData.attributes.entries
      .expand(
        (personal) => [
          Opacity(
            opacity: 0.8,
            child: Text(
              personal.key.name[_lang],
              style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          BlurText(
            text: personal.value[_lang],
            theme: IrmaTheme.of(context).textTheme.body2.copyWith(color: irmaCardTheme.fgColor),
            color: irmaCardTheme.fgColor,
            isTextBlurred: false,
          ),
          SizedBox(
            height: IrmaTheme.of(context).smallSpacing,
          ),
        ],
      )
      .toList();

  Widget getIssuer(BuildContext context, TextStyle bodyTheme) => Padding(
        padding: EdgeInsets.only(
          top: IrmaTheme.of(context).smallSpacing,
          left: IrmaTheme.of(context).defaultSpacing,
          right: IrmaTheme.of(context).defaultSpacing,
        ),
        child: Row(
          children: [
            Container(
              width: _indent,
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  FlutterI18n.translate(context, 'wallet.issuer'),
                  style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: Text(
                issuer.name[_lang],
                style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget getExpiration(BuildContext context, TextStyle bodyTheme) => Padding(
        padding: EdgeInsets.only(
          bottom: IrmaTheme.of(context).smallSpacing,
          left: IrmaTheme.of(context).defaultSpacing,
          right: IrmaTheme.of(context).defaultSpacing,
        ),
        child: Row(
          children: [
            Container(
              width: _indent,
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  FlutterI18n.translate(context, 'wallet.expiration'),
                  style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: Text(
                getReadableDate(personalData.expires, _lang),
                style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  String getReadableDate(DateTime date, String lang) {
    return DateFormat.yMMMMd(lang).format(date);
  }
}

Widget photoCard({Widget card, Widget photoCard, bool applyPhoto}) => applyPhoto
    ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          photoCard,
          Expanded(child: card),
        ],
      )
    : card;
