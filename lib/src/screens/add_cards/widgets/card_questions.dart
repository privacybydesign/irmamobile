import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/collapsible_helper.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';

class CardQuestions extends StatefulWidget {
  const CardQuestions({this.credentialType, this.parentKey, this.parentScrollController});

  final CredentialType credentialType;
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _CardQuestionsState createState() => _CardQuestionsState();
}

class _CardQuestionsState extends State<CardQuestions> with TickerProviderStateMixin {
  final List<GlobalKey> _collapsableKeys = List<GlobalKey>.generate(3, (int index) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.purpose_question'),
            onExpansionChanged: (v) =>
                {if (v) jumpToCollapsable(widget.parentScrollController, widget.parentKey, _collapsableKeys[0])},
            content: SizedBox(
              width: double.infinity,
              child: Text(
                getTranslation(widget.credentialType.faqPurpose).replaceAll('\\n', '\n'),
                style: IrmaTheme.of(context).textTheme.body1,
                textAlign: TextAlign.left,
              ),
            ),
            key: _collapsableKeys[0]),
        Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.content_question'),
            onExpansionChanged: (v) =>
                {if (v) jumpToCollapsable(widget.parentScrollController, widget.parentKey, _collapsableKeys[1])},
            content: SizedBox(
              width: double.infinity,
              child: Text(
                getTranslation(widget.credentialType.faqContent).replaceAll('\\n', '\n'),
                style: IrmaTheme.of(context).textTheme.body1,
                textAlign: TextAlign.left,
              ),
            ),
            key: _collapsableKeys[1]),
        Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.howto_question'),
            onExpansionChanged: (v) =>
                {if (v) jumpToCollapsable(widget.parentScrollController, widget.parentKey, _collapsableKeys[2])},
            content: SizedBox(
              width: double.infinity,
              child: Text(
                getTranslation(widget.credentialType.faqHowto).replaceAll('\\n', '\n'),
                style: IrmaTheme.of(context).textTheme.body1,
                textAlign: TextAlign.left,
              ),
            ),
            key: _collapsableKeys[2]),
      ],
    );
  }
}
