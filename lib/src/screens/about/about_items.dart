import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/about/widgets/links.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/collapsible.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutItems extends StatefulWidget {
  const AboutItems({this.credentialType, this.parentKey, this.parentScrollController});

  final CredentialType credentialType;
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _AboutItemsState createState() => _AboutItemsState();
}

class _AboutItemsState extends State<AboutItems> with TickerProviderStateMixin {
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
            header: FlutterI18n.translate(context, 'about.who_is_behind_irma_item'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(0))},
            content: WhoIsBehindIrma(),
            key: _collapsableKeys[0]),
        Collapsible(
            header: FlutterI18n.translate(context, 'about.why_irma_item'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(1))},
            content: WhyIrma(),
            key: _collapsableKeys[1]),
        Collapsible(
            header: FlutterI18n.translate(context, 'about.privacy_item'),
            onExpansionChanged: (v) => {if (v) Future.delayed(expandDuration, () => _jumpToCollapsable(2))},
            content: PrivacyAndSecurity(),
            key: _collapsableKeys[2]),
      ],
    );
  }
}

// TODO: The order of the bold and non-bold elements might differ in another language!
class WhoIsBehindIrma extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RichText(
          text: TextSpan(
              text: FlutterI18n.translate(context, 'about.who_is_behind_irma_explanation_1'),
              style: IrmaTheme.of(context).textTheme.body1,
              children: <TextSpan>[
                TextSpan(text: FlutterI18n.translate(context, 'about.pbdf'), style: IrmaTheme.of(context).boldBody),
                TextSpan(
                    text: FlutterI18n.translate(context, 'about.who_is_behind_irma_explanation_2'),
                    style: IrmaTheme.of(context).textTheme.body1),
              ]),
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        Text(FlutterI18n.translate(context, 'about.who_is_behind_irma_explanation_3'),
            style: IrmaTheme.of(context).textTheme.body1),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        SizedBox(
          width: double.infinity,
          child: Container(
            child: Text(
              FlutterI18n.translate(context, 'about.check_out'),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        ExternalLink("about.pbdf_link", "about.pbdf",
            SizedBox(width: 50.0, child: Image.asset("assets/non-free/pbdf_logo.png"))),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        ExternalLink("about.award_link", "about.award",
            SizedBox(width: 50.0, child: Image.asset("assets/non-free/award_logo.png"))),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
      ],
    );
  }
}

// TODO: The order of the bold and non-bold elements might differ in another language!
class WhyIrma extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RichText(
          text: TextSpan(
              text: FlutterI18n.translate(context, 'about.why_irma_item_1'),
              style: IrmaTheme.of(context).boldBody,
              children: <TextSpan>[
                TextSpan(
                    text: FlutterI18n.translate(context, 'about.why_irma_item_2'),
                    style: IrmaTheme.of(context).textTheme.body1),
              ]),
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        RichText(
          text: TextSpan(
              text: FlutterI18n.translate(context, 'about.why_irma_item_3'),
              style: IrmaTheme.of(context).textTheme.body1,
              children: <TextSpan>[
                TextSpan(
                  text: FlutterI18n.translate(context, 'about.avg'),
                  style: IrmaTheme.of(context).hyperlinkTextStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launch(FlutterI18n.translate(context, 'about.avg_link'));
                    },
                ),
                TextSpan(
                    text: FlutterI18n.translate(context, 'about.why_irma_item_4'),
                    style: IrmaTheme.of(context).textTheme.body1),
              ]),
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        RichText(
          text: TextSpan(
              text: FlutterI18n.translate(context, 'about.why_irma_item_5'),
              style: IrmaTheme.of(context).boldBody,
              children: <TextSpan>[
                TextSpan(
                    text: FlutterI18n.translate(context, 'about.why_irma_item_6'),
                    style: IrmaTheme.of(context).textTheme.body1),
              ]),
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
      ],
    );
  }
}

// TODO: The order of the bold and non-bold elements might differ in another language!
class PrivacyAndSecurity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(FlutterI18n.translate(context, 'about.privacy_explanation_1'),
            style: IrmaTheme.of(context).textTheme.body1),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        RichText(
          text: TextSpan(
              text: FlutterI18n.translate(context, 'about.privacy_explanation_2'),
              style: IrmaTheme.of(context).textTheme.body1,
              children: <TextSpan>[
                TextSpan(
                  text: FlutterI18n.translate(context, 'about.privacy_explanation_3'),
                  style: IrmaTheme.of(context).boldBody,
                ),
                TextSpan(
                  text: FlutterI18n.translate(context, 'about.privacy_explanation_4'),
                  style: IrmaTheme.of(context).textTheme.body1,
                ),
              ]),
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        RichText(
          text: TextSpan(
              text: FlutterI18n.translate(context, 'about.privacy_explanation_5'),
              style: IrmaTheme.of(context).textTheme.body1,
              children: <TextSpan>[
                TextSpan(
                    text: FlutterI18n.translate(context, 'about.privacy_explanation_6'),
                    style: IrmaTheme.of(context).boldBody),
              ]),
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
        Text(FlutterI18n.translate(context, 'about.privacy_explanation_7'),
            style: IrmaTheme.of(context).textTheme.body1),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        SizedBox(
          width: double.infinity,
          child: Container(
            child: Text(
              FlutterI18n.translate(context, 'about.check_out'),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        SizedBox(height: IrmaTheme.of(context).smallSpacing),
        const ExternalLink(
          "about.privacy_policy_link",
          "about.privacy_policy",
          Icon(IrmaIcons.view, size: 16.0),
        ),
        SizedBox(height: IrmaTheme.of(context).defaultSpacing),
      ],
    );
  }
}
