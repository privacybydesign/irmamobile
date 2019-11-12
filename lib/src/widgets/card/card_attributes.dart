import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/blurtext.dart';

class CardAttributes extends StatelessWidget {
  static const transparentWhite = Color(0xaaffffff);
  static const indent = 100.0;

  final Credential personalData;
  final Issuer issuer; // Object is String | Color
  final bool isCardUnblurred;
  final String lang;
  final IrmaCardTheme irmaCardTheme;
  final _yearMonthDateFormat = DateFormat.yMd();

  CardAttributes({this.personalData, this.issuer, this.isCardUnblurred, this.lang, this.irmaCardTheme});

  @override
  Widget build(BuildContext context) {
    final List<Widget> textLines = <Widget>[
      const Divider(color: transparentWhite),
    ];

    textLines.addAll(personalData.attributes.entries.where((personal) {
      return personal.key.name['nl'] != "Expiration";
    }).map((personal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: indent,
              child: Text(personal.key.name['nl'],
                  style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
            ),
            BlurText(text: personal.value['nl'], color: irmaCardTheme.fgColor, isTextBlurred: false),
//            _BlurText(personal.value, IrmaCardTheme.fgColor,
//              personal.hidden == 'true' && !isCardUnblurred),
          ],
        ),
      );
    }));

    textLines.add(const Divider(color: transparentWhite));

    textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text(FlutterI18n.translate(context, 'wallet.issuer'),
                style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text(FlutterI18n.translate(context, 'wallet.expiration'),
                style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            _yearMonthDateFormat.format(personalData.expires),
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
