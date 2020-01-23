import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/disclosure_card.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_dialog.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisclosureScreen extends StatefulWidget {
  static const String routeName = '/disclosure';

  final List<List<VerifierCredential>> issuers;

  const DisclosureScreen(this.issuers) : super();

  @override
  _DisclosureScreenState createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends State<DisclosureScreen> {
  final _lang = ui.window.locale.languageCode;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => showExplanation());

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(FlutterI18n.translate(context, 'disclosure.title')),
        ),
        backgroundColor: IrmaTheme.of(context).grayscaleWhite,
        body: ListView(
          padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: IrmaTheme.of(context).mediumSpacing, horizontal: IrmaTheme.of(context).smallSpacing),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: FlutterI18n.translate(context, 'disclosure.intro.start'),
                      style: IrmaTheme.of(context).textTheme.body1),
                  TextSpan(text: "Gemeente Amsterdam", style: IrmaTheme.of(context).textTheme.body2),
                  TextSpan(
                      text: FlutterI18n.translate(context, 'disclosure.intro.end'),
                      style: IrmaTheme.of(context).textTheme.body1),
                ]),
              ),
            ),
            DisclosureCard(widget.issuers),
          ],
        ),
      );

  void showExplanation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool showDisclosureDialog = prefs.getBool('showDisclosureDialog') ?? true;
    final hasChoice = widget.issuers.any((List<VerifierCredential> issuerList) => issuerList.length > 1);

    if (showDisclosureDialog && hasChoice) {
      showDialog(
        context: context,
        builder: (BuildContext context) => IrmaDialog(
          title: 'disclosure.explanation.title',
          content: 'disclosure.explanation.body',
          image: 'assets/disclosure/disclosure-explanation.webp',
          child: Wrap(
            direction: Axis.horizontal,
            verticalDirection: VerticalDirection.up,
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              IrmaTextButton(
                onPressed: () async {
                  await prefs.setBool('showDisclosureDialog', false);
                  Navigator.of(context).pop();
                },
                minWidth: 0.0,
                label: 'disclosure.explanation.dismiss-remember',
              ),
              IrmaButton(
                size: IrmaButtonSize.small,
                minWidth: 0.0,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                label: 'disclosure.explanation.dismiss',
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget carouselWidget(VerifierCredential credential) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...credential.attributes.entries
              .map(
                (personal) => Padding(
                  padding: EdgeInsets.only(
                    top: IrmaTheme.of(context).smallSpacing,
                    left: IrmaTheme.of(context).defaultSpacing,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personal.key.name[_lang],
                        style: IrmaTheme.of(context)
                            .textTheme
                            .body1
                            .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        personal.value[_lang],
                        style: IrmaTheme.of(context).textTheme.body1,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      FlutterI18n.translate(context, 'disclosure.issuer'),
                      style: IrmaTheme.of(context)
                          .textTheme
                          .body1
                          .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: IrmaTheme.of(context).smallSpacing),
                  child: Text(
                    credential.issuer,
                    style: IrmaTheme.of(context)
                        .textTheme
                        .body1
                        .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
