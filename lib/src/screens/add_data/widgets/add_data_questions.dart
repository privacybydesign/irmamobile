import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../util/collapsible_helper.dart';
import '../../../util/language.dart';
import '../../../widgets/collapsible.dart';

class AddDataQuestions extends StatefulWidget {
  const AddDataQuestions({
    required this.credentialType,
    required this.parentScrollController,
  });

  final CredentialType credentialType;
  final ScrollController parentScrollController;

  @override
  _AddDataQuestionsState createState() => _AddDataQuestionsState();
}

class _AddDataQuestionsState extends State<AddDataQuestions> with TickerProviderStateMixin {
  final List<GlobalKey> _collapsableKeys = List<GlobalKey>.generate(3, (int index) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.credentialType.faqPurpose.isNotEmpty)
          Collapsible(
              header: FlutterI18n.translate(context, 'add_data_details.purpose_question'),
              onExpansionChanged: (v) => {if (v) jumpToCollapsable(widget.parentScrollController, _collapsableKeys[0])},
              content: SizedBox(
                width: double.infinity,
                child: Text(
                  getTranslation(context, widget.credentialType.faqPurpose).replaceAll('\\n', '\n'),
                  style: IrmaTheme.of(context).textTheme.bodyText2,
                  textAlign: TextAlign.left,
                ),
              ),
              key: _collapsableKeys[0]),
        if (widget.credentialType.faqContent.isNotEmpty)
          Collapsible(
              header: FlutterI18n.translate(context, 'add_data_details.content_question'),
              onExpansionChanged: (v) => {if (v) jumpToCollapsable(widget.parentScrollController, _collapsableKeys[1])},
              content: SizedBox(
                width: double.infinity,
                child: Text(
                  getTranslation(context, widget.credentialType.faqContent).replaceAll('\\n', '\n'),
                  style: IrmaTheme.of(context).textTheme.bodyText2,
                  textAlign: TextAlign.left,
                ),
              ),
              key: _collapsableKeys[1]),
        if (widget.credentialType.faqHowto.isNotEmpty)
          Collapsible(
              header: FlutterI18n.translate(context, 'add_data_details.howto_question'),
              onExpansionChanged: (v) => {if (v) jumpToCollapsable(widget.parentScrollController, _collapsableKeys[2])},
              content: SizedBox(
                width: double.infinity,
                child: Text(
                  getTranslation(context, widget.credentialType.faqHowto).replaceAll('\\n', '\n'),
                  style: IrmaTheme.of(context).textTheme.bodyText2,
                  textAlign: TextAlign.left,
                ),
              ),
              key: _collapsableKeys[2]),
      ],
    );
  }
}
