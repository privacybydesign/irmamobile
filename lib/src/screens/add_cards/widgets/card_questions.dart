import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/add_cards/customs/configurable_expansion_tile.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';

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
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.purpose_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(0))},
            content: getTranslation(widget.credentialType.faqPurpose).replaceAll('\\n', '\n'),
            key: _collapsableKeys[0]),
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.content_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(1))},
            content: getTranslation(widget.credentialType.faqContent).replaceAll('\\n', '\n'),
            key: _collapsableKeys[1]),
        _Collapsible(
            header: FlutterI18n.translate(context, 'card_store.card_info.howto_question'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(2))},
            content: getTranslation(widget.credentialType.faqHowto).replaceAll('\\n', '\n'),
            key: _collapsableKeys[2]),
      ],
    );
  }
}

class _Collapsible extends StatelessWidget {
  final String header;
  final String content;
  const _Collapsible({Key key, this.header, this.content, this.onExpansionChanged}) : super(key: key);
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    return ConfigurableExpansionTile(
      onExpansionChanged: onExpansionChanged,
      initiallyExpanded: false,
      animatedWidgetFollowingHeader: const Padding(
        padding: EdgeInsets.all(4.0),
        child: Icon(
          Icons.expand_more,
          color: Colors.black,
        ),
      ),

      header: Expanded(
        child: Padding(
          padding: EdgeInsets.all(IrmaTheme.of(context).tinySpacing * 3),
          child: Text(
            header,
            style: IrmaTheme.of(context).collapseTextStyle,
          ),
        ),
      ),
      headerExpanded: Expanded(
        child: Padding(
          padding: EdgeInsets.all(IrmaTheme.of(context).tinySpacing * 3),
          child: Text(
            header,
            style: IrmaTheme.of(context).textTheme.display2,
          ),
        ),
      ),
      headerBackgroundColorStart: IrmaTheme.of(context).backgroundBlue,
      expandedBackgroundColor: const Color(0x00000000), // TODO: define transparent in theme
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
          child: Text(
            content,
            style: IrmaTheme.of(context).textTheme.body1,
          ),
        )
      ],
    );
  }
}
