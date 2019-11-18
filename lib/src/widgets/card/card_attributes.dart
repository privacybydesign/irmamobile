import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/blurtext.dart';

class CardAttributes extends StatelessWidget {
  static const _transparentWhite = Color(0xaaffffff);
  final _indent = 100.0;

  final _formatter = DateFormat.yMd();

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
    TextStyle bodyTheme = Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor);

    final List<Widget> _textLines = <Widget>[
      const Divider(color: _transparentWhite),
    ];

    _textLines.addAll(getAttributes(context, bodyTheme));
    _textLines.add(const Divider(color: _transparentWhite));
    _textLines.add(getIssuer(context, bodyTheme));
    _textLines.add(getExpiration(context, bodyTheme));

    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.offset < 0) {
        scrollOverflowCallback(-scrollController.offset);
      }
    });

    return Scrollbar(
        child: ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      children: _textLines,
    ));
  }

  List<Widget> getAttributes(BuildContext context, TextStyle bodyTheme) {
    return personalData.attributes.entries.map((personal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: _indent,
              child: Text(
                personal.key.name['nl'],
                style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor),
              ),
            ),
            BlurText(text: personal.value['nl'], color: irmaCardTheme.fgColor, isTextBlurred: false),
          ],
        ),
      );
    }).toList();
  }

  Widget getIssuer(BuildContext context, TextStyle bodyTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: _indent,
            child: Text(
              FlutterI18n.translate(context, 'wallet.issuer'),
              style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor),
            ),
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
    );
  }

  Widget getExpiration(BuildContext context, TextStyle bodyTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: _indent,
            child: Text(
              FlutterI18n.translate(context, 'wallet.expiration'),
              style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor),
            ),
          ),
          Text(
            _formatter.format(personalData.expires),
            style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(fontWeight: FontWeight.w700)
                .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    );
  }
}
