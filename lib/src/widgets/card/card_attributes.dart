import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/card/backgrounds.dart';
import 'package:irmamobile/src/widgets/card/blurtext.dart';

class CardAttributes extends StatelessWidget {
  static const transparentWhite = Color(0xaaffffff);
  static const indent = 100.0;

  final _formatter = DateFormat.yMd();

  final Credential personalData;
  final Issuer issuer; // Object is String | Color
  final bool isCardUnblurred;
  final String lang;
  final IrmaCardTheme irmaCardTheme;
  final void Function(double) scrollOverflowCallback;

  CardAttributes(
  {this.personalData, this.issuer, this.isCardUnblurred, this.lang, this.irmaCardTheme, this.scrollOverflowCallback});

  @override
  Widget build(BuildContext context) {
    final List<Widget> _textLines = <Widget>[
      const Divider(color: transparentWhite),
    ];

    _textLines.addAll(personalData.attributes.entries.where((personal) {
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

    _textLines.add(const Divider(color: transparentWhite));

    _textLines.add(Padding(
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

    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text(FlutterI18n.translate(context, 'wallet.expiration'),
              style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
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
    ));

////////////
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
    _textLines.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: indent,
            child: Text("Filler", style: Theme.of(context).textTheme.body1.copyWith(color: irmaCardTheme.fgColor)),
          ),
          Text(
            "Filler",
            style: Theme.of(context)
              .textTheme
              .body1
              .copyWith(fontWeight: FontWeight.w700)
              .copyWith(color: irmaCardTheme.fgColor),
          ),
        ],
      ),
    ));
////////////

    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
//      print(
//          "offset ${scrollController.offset}, maxScrollExtent ${scrollController.position.maxScrollExtent}, outOfRange ${scrollController.position.outOfRange}");
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
}
