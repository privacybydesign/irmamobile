import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:irmamobile/src/models/credential.dart';
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
  final void Function(double) scrollOverflowCallback;

  CardAttributes(
      {this.personalData, this.issuer, this.isCardUnblurred, this.irmaCardTheme, this.scrollOverflowCallback});

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
            constraints: BoxConstraints(
              minHeight: _minHeight,
            ),
            child: Scrollbar(
              child: ListView(
                shrinkWrap: true,
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...getAttributes(context, bodyTheme),
                ],
              ),
            ),
          ),
        ),
        Column(
          children: <Widget>[getIssuer(context, bodyTheme), getExpiration(context, bodyTheme)],
        ),
      ],
    );
  }

  List<Widget> getAttributes(BuildContext context, TextStyle bodyTheme) => personalData.attributes.entries
      .map((personal) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _indent,
                  margin: const EdgeInsets.only(top: 2),
                  child: Opacity(
                    opacity: 0.8,
                    child: Text(
                      personal.key.name[_lang],
                      style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                BlurText(
                    text: personal.value[_lang],
                    theme: IrmaTheme.of(context).textTheme.body2.copyWith(color: irmaCardTheme.fgColor),
                    color: irmaCardTheme.fgColor,
                    isTextBlurred: false),
              ],
            ),
          ))
      .toList();

  Widget getIssuer(BuildContext context, TextStyle bodyTheme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
                width: _indent,
                margin: const EdgeInsets.only(top: 1),
                child: Opacity(
                  opacity: 0.8,
                  child: Text(
                    FlutterI18n.translate(context, 'wallet.issuer'),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
                  ),
                )),
            Text(
              issuer.name[_lang],
              style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
            ),
          ],
        ),
      );

  Widget getExpiration(BuildContext context, TextStyle bodyTheme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: _indent,
              margin: const EdgeInsets.only(top: 1),
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  FlutterI18n.translate(context, 'wallet.expiration'),
                  style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
                ),
              ),
            ),
            Text(
              getReadableDate(personalData.expires, _lang),
              style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
            ),
          ],
        ),
      );

  String getReadableDate(DateTime date, String lang) {
    return DateFormat.yMMMMd(lang).format(date);
  }
}
