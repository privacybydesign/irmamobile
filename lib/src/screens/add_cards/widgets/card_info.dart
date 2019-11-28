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
      left: IrmaTheme.of(context).smallSpacing,
      right: IrmaTheme.of(context).smallSpacing,
    );

    final paddingQuestions = EdgeInsets.only(
      left: IrmaTheme.of(context).tinySpacing,
      right: IrmaTheme.of(context).tinySpacing,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              color: IrmaTheme.of(context).grayscale60,
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.only(top: 60),
                width: 75,
                height: 75,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).smallSpacing),
                  child: logoFile.existsSync() ? Image.file(logoFile) : Image.asset("assets/non-free/irmalogo.png"),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: paddingText,
          child: Text(
            FlutterI18n.translate(
              context,
              'card_store.card_info.header_credential_type',
              {
                'credential_type': getTranslation(widget.credentialType.name),
              },
            ),
            style: Theme.of(context).textTheme.headline,
          ),
        ),
        SizedBox(
          height: IrmaTheme.of(context).spacing,
        ),
        Padding(
          padding: paddingText,
          child: Text(
            getTranslation(widget.credentialType.faqIntro),
          ),
        ),
        SizedBox(
          height: IrmaTheme.of(context).spacing,
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
