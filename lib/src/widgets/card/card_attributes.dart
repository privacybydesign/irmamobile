import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/blurtext.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CardAttributes extends StatelessWidget {
  final _indent = 100.0;

  final Credential personalData;
  final Issuer issuer;
  final bool isCardUnblurred;
  final String lang;
  final IrmaCardTheme irmaCardTheme;
  final void Function(double) scrollOverflowCallback;

  CardAttributes(
      {this.personalData,
      this.issuer,
      this.isCardUnblurred,
      this.lang,
      this.irmaCardTheme,
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
        Expanded(
          child: Scrollbar(
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              children: [
                ...getAttributes(context, bodyTheme),
              ],
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
                  child: Text(
                    personal.key.name['nl'],
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                BlurText(
                    text: personal.value['nl'],
                    theme: IrmaTheme.of(context)
                        .textTheme
                        .body2
                        .copyWith(color: irmaCardTheme.fgColor, fontWeight: FontWeight.w700),
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
              child: Text(
                FlutterI18n.translate(context, 'wallet.issuer'),
                style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
              ),
            ),
            Text(
              issuer.name['nl'],
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
              child: Text(
                FlutterI18n.translate(context, 'wallet.expiration'),
                style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
              ),
            ),
            Text(
              getReadableDate(personalData.expires, 'nl'),
              style: IrmaTheme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor, fontSize: 12),
            ),
          ],
        ),
      );

  String getReadableDate(DateTime date, String lang) {
    return DateFormat.yMMMMd(lang).format(date);
  }
}
