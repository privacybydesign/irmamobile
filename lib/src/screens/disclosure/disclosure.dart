import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/models/verifier.dart';
import 'package:irmamobile/src/widgets/irma_message.dart';

import 'carousel.dart';

class DisclosureScreen extends StatefulWidget {
  static const String routeName = '/disclosure';

  final List<List<VerifierCredential>> issuers;

  static const _indent = 100.0;

  const DisclosureScreen(this.issuers) : super();

  @override
  _DisclosureScreenState createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends State<DisclosureScreen> {
  final _lang = ui.window.locale.languageCode;

  @override
  Widget build(BuildContext context) {
    final _hasChoice = widget.issuers.any((List<VerifierCredential> issuerList) => issuerList.length > 1);

    return Scaffold(
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
          if (_hasChoice)
            Padding(
              padding: EdgeInsets.only(bottom: IrmaTheme.of(context).mediumSpacing),
              child: IrmaMessage(
                FlutterI18n.translate(context, 'disclosure.info.title'),
                FlutterI18n.translate(context, 'disclosure.info.body'),
                type: IrmaMessageType.info,
              ),
            ),
          Card(
            elevation: 1.0,
            semanticContainer: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IrmaTheme.of(context).defaultSpacing),
              side: const BorderSide(color: Color(0xFFDFE3E9), width: 1),
            ),
            color: IrmaTheme.of(context).primaryLight,
            child: Column(
              children: [
                SizedBox(height: IrmaTheme.of(context).smallSpacing),
                ...widget.issuers
                    .expand(
                      (issuerList) => [
                        if (issuerList != widget.issuers[0])
                          Divider(
                            color: IrmaTheme.of(context).grayscale80,
                          ),
                        Carousel(credentialSet: issuerList.map((issuer) => carouselWidget(issuer)).toList())
                      ],
                    )
                    .toList(),
                SizedBox(height: IrmaTheme.of(context).smallSpacing),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: IrmaTheme.of(context).mediumSpacing, horizontal: IrmaTheme.of(context).smallSpacing),
            child: Text(
              FlutterI18n.translate(context, 'disclosure.footer'),
              style: IrmaTheme.of(context).textTheme.body1,
            ),
          ),
        ],
      ),
    );
  }

  Widget carouselWidget(VerifierCredential credential) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
      child: Column(
        children: <Widget>[
          ...credential.attributes.entries
              .map((personal) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: DisclosureScreen._indent,
                        margin: const EdgeInsets.only(top: 2),
                        child: Text(
                          personal.key.name[_lang],
                          style: IrmaTheme.of(context)
                              .textTheme
                              .body1
                              .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        personal.value[_lang],
                        style: IrmaTheme.of(context).textTheme.body1,
                      ),
                    ],
                  ))
              .toList(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: DisclosureScreen._indent,
                  child: Opacity(
                    opacity: 0.8,
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
                Text(
                  credential.issuer,
                  style: IrmaTheme.of(context)
                      .textTheme
                      .body1
                      .copyWith(color: IrmaTheme.of(context).grayscale40, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
