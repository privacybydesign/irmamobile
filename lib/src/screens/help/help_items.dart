// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/util/collapsible_helper.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class HelpItems extends StatefulWidget {
  const HelpItems({this.credentialType, this.parentKey, this.parentScrollController});

  final CredentialType credentialType;
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _HelpItemsState createState() => _HelpItemsState();
}

class _HelpItemsState extends State<HelpItems> with TickerProviderStateMixin {
  final List<GlobalKey> _collapsableKeys = List<GlobalKey>.generate(6, (int index) => GlobalKey());

  Function(bool) onExpansionChangedForIndex(int index) {
    return (isExpanded) {
      if (isExpanded) {
        jumpToCollapsable(widget.parentScrollController, widget.parentKey, _collapsableKeys[index]);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Collapsible(
            header: FlutterI18n.translate(context, 'help.question_1'),
            onExpansionChanged: onExpansionChangedForIndex(0),
            content: Container(
              child: const TranslatedText('help.answer_1'),
            ),
            key: _collapsableKeys[0]),
        Collapsible(
            header: FlutterI18n.translate(context, 'help.question_2'),
            onExpansionChanged: onExpansionChangedForIndex(1),
            content: Container(
              child: const TranslatedText('help.answer_2'),
            ),
            key: _collapsableKeys[1]),
        Collapsible(
            header: FlutterI18n.translate(context, 'help.question_3'),
            onExpansionChanged: onExpansionChangedForIndex(2),
            content: Container(
              child: const TranslatedText('help.answer_3'),
            ),
            key: _collapsableKeys[2]),
        Collapsible(
            header: FlutterI18n.translate(context, 'help.question_4'),
            onExpansionChanged: onExpansionChangedForIndex(3),
            content: Container(
              child: const TranslatedText('help.answer_4'),
            ),
            key: _collapsableKeys[3]),
        Collapsible(
            header: FlutterI18n.translate(context, 'help.question_5'),
            onExpansionChanged: onExpansionChangedForIndex(4),
            content: Container(
              child: const TranslatedText('help.answer_5'),
            ),
            key: _collapsableKeys[4]),
        Collapsible(
            header: FlutterI18n.translate(context, 'help.question_6'),
            onExpansionChanged: onExpansionChangedForIndex(5),
            content: Container(
              child: const TranslatedText('help.answer_6'),
            ),
            key: _collapsableKeys[5]),
      ],
    );
  }
}
