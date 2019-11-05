import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:intl/intl.dart';

import 'backgrounds.dart';
import 'blurtext.dart';

class CardPersonalData extends StatelessWidget {
  static const transparentWhite = Color(0xaaffffff);
  static const indent = 100.0;

  final Credential personalData;
  final Issuer issuer; // Object is String | Color
  final bool isCardUnblurred;
  final String lang;
  final IrmaCardTheme irmaCardTheme;
  final formatter = new DateFormat.yMd();

  CardPersonalData(this.personalData, this.issuer, this.isCardUnblurred, this.lang, this.irmaCardTheme);

  Widget build(BuildContext context) {
    List<Widget> textLines = <Widget>[
      Divider(color: transparentWhite),
    ];

    textLines.addAll(personalData.attributes.entries.where((personal) {
      return personal.key.name['nl'] != "Expiration";
    }).map((personal) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              child: Text(personal.key.name['nl'], style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
              width: indent,
            ),
            BlurText(personal.value['nl'], irmaCardTheme.fgColor, false),
//            _BlurText(personal.value, IrmaCardTheme.fgColor,
//              personal.hidden == 'true' && !isCardUnblurred),
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
            child: Text(FlutterI18n.translate(context, 'wallet.issuer'),
              style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
            width: indent,
          ),
          Text(
            issuer.name['nl'],
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));

    textLines.add(Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            child: Text(FlutterI18n.translate(context, 'wallet.expiration'),
              style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
            width: indent,
          ),
          Text(
            formatter.format(personalData.expires),
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
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
