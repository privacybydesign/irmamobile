import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/credentials.dart';
import '../../theme/theme.dart';
import '../irma_card.dart';
import '../irma_divider.dart';
import 'yivi_credential_card_header.dart';

class CredentialTypeInfoCard extends StatelessWidget {
  const CredentialTypeInfoCard({super.key, required this.info});

  final CredentialTypeInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final String lang = FlutterI18n.currentLocale(context)!.languageCode;
    final name = info.name.translate(lang);
    final issuerName = info.issuerName.translate(lang);

    return IrmaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YiviCredentialCardHeader(credentialName: name, issuerName: issuerName, compact: true),
          IrmaDivider(padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing)),
          ...info.attributes.values.map((value) => Text('• ${value.translate(lang)}'))
        ],
      ),
    );
  }
}
