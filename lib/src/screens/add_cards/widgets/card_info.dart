import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/add_cards/customs/future_card.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/card_questions.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CardInfo extends StatefulWidget {
  const CardInfo(this.name, this.issuer, this.logoPath, this.parentKey, this.parentScrollController);

  final String name;
  final String issuer;
  final String logoPath;
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _CardInfoState createState() => _CardInfoState();
}

class _CardInfoState extends State<CardInfo> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: IrmaTheme.of(context).spacing,
          ),
          FutureCard(widget.name, widget.issuer, widget.logoPath),
          SizedBox(
            height: IrmaTheme.of(context).spacing,
          ),
          Text(
            FlutterI18n.translate(context, 'card_store.card_info.general_info'),
          ),
          SizedBox(
            height: IrmaTheme.of(context).spacing,
          ),
          CardQuestions(
            widget.parentKey,
            widget.parentScrollController,
          )
        ],
      ),
    );
  }
}
