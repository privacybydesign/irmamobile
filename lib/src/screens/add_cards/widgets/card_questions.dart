import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/theme.dart';
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
  Duration expandDuration = const Duration(milliseconds: 200); // expand duration of _Collapsible

  void _jumpToCollapsable(int index) {
    final RenderObject scrollview = widget.parentKey.currentContext.findRenderObject();
    final RenderBox collapsable = _collapsableKeys[index].currentContext.findRenderObject() as RenderBox;
    widget.parentScrollController.animateTo(
      collapsable.localToGlobal(Offset(0, widget.parentScrollController.offset), ancestor: scrollview).dy,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.purpose_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(0))},
            content: Text(getTranslation(widget.credentialType.faqPurpose).replaceAll('\\n', '\n'),
                style: IrmaTheme.of(context).textTheme.body1),
            key: _collapsableKeys[0]),
        Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.content_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(1))},
            content: Text(getTranslation(widget.credentialType.faqContent).replaceAll('\\n', '\n'),
                style: IrmaTheme.of(context).textTheme.body1),
            key: _collapsableKeys[1]),
        Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.howto_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(2))},
            content: Text(getTranslation(widget.credentialType.faqHowto).replaceAll('\\n', '\n'),
                style: IrmaTheme.of(context).textTheme.body1),
            key: _collapsableKeys[2]),
      ],
    );
  }
}
