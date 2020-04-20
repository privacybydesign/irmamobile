import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/card_questions.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';

class CardInfo extends StatefulWidget {
  const CardInfo({this.irmaConfiguration, this.credentialType, this.parentKey, this.parentScrollController});

  final IrmaConfiguration irmaConfiguration;
  final CredentialType credentialType;
  final GlobalKey parentKey;
  final ScrollController parentScrollController;

  @override
  _CardInfoState createState() => _CardInfoState();
}

class _CardInfoState extends State<CardInfo> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final logoFile = File(widget.credentialType.logoPath(widget.irmaConfiguration.path));
    final paddingText = EdgeInsets.only(
      left: IrmaTheme.of(context).defaultSpacing,
      right: IrmaTheme.of(context).defaultSpacing,
    );

    final paddingQuestions = EdgeInsets.only(
      left: IrmaTheme.of(context).smallSpacing,
      right: IrmaTheme.of(context).smallSpacing,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: 112,
              color: IrmaTheme.of(context).grayscale60,
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: IrmaTheme.of(context).grayscaleWhite,
                  border: Border.all(
                    color: IrmaTheme.of(context).grayscale90,
                    width: 3,
                  ),
                ),
                margin: const EdgeInsets.only(top: 78),
                width: 68,
                height: 68,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                  child: logoFile.existsSync() ? Image.file(logoFile) : Image.asset("assets/non-free/irmalogo.png"),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: IrmaTheme.of(context).mediumSpacing,
        ),
        Padding(
          padding: paddingText,
          child: Text(
            FlutterI18n.translate(
              context,
              'card_store.card_info.header_credential_type',
              translationParams: {'credential_type': getTranslation(context, widget.credentialType.name)},
            ),
            style: Theme.of(context).textTheme.headline,
          ),
        ),
        SizedBox(
          height: IrmaTheme.of(context).defaultSpacing,
        ),
        Padding(
          padding: paddingText,
          child: Text(
            getTranslation(context, widget.credentialType.faqIntro).replaceAll('\\n', '\n'),
            style: IrmaTheme.of(context).textTheme.body1,
          ),
        ),
        SizedBox(
          height: IrmaTheme.of(context).defaultSpacing,
        ),
        Padding(
          padding: paddingQuestions,
          child: CardQuestions(
            credentialType: widget.credentialType,
            parentKey: widget.parentKey,
            parentScrollController: widget.parentScrollController,
          ),
        )
      ],
    );
  }
}
