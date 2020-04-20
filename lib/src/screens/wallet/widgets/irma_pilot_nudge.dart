import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/future_card.dart';
import 'package:url_launcher/url_launcher.dart';

class IrmaPilotNudge extends StatelessWidget {
  final CredentialType credentialType;
  final Issuer issuer;
  final String irmaConfigurationPath;
  final void Function(BuildContext context) showLaunchFailDialog;

  const IrmaPilotNudge({
    this.credentialType,
    this.issuer,
    this.irmaConfigurationPath,
    this.showLaunchFailDialog,
  });

  @override
  Widget build(BuildContext context) {
    final translationScope = 'wallet.${credentialType.fullId.replaceAll('.', '_')}';
    final translatedIssueUrl = getTranslation(context, credentialType.issueUrl);

    final logoFile = File(issuer.logoPath(irmaConfigurationPath));

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            bottom: IrmaTheme.of(context).defaultSpacing,
            left: IrmaTheme.of(context).smallSpacing,
            right: IrmaTheme.of(context).smallSpacing,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final didLaunch = await launch(
              translatedIssueUrl,
              forceSafariVC: false,
              universalLinksOnly: credentialType.isULIssueUrl,
            );

            if (!didLaunch) {
              showLaunchFailDialog(context);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(IrmaTheme.of(context).tinySpacing / 2),
            child: FutureCard(
              logoImage: logoFile.existsSync() ? Image.file(logoFile) : Image.asset("assets/issuers/personaldata.png"),
              content: FlutterI18n.translate(context, '$translationScope.nudge'),
            ),
          ),
        ),
      ],
    );
  }
}
