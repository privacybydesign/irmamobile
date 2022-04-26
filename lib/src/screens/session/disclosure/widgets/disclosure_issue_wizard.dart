import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/widgets/irma_card.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../bloc/disclosure_permission_state.dart';
import 'irma_disclosure_credential_card.dart';

class DisclosureIssueWizard extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;

  const DisclosureIssueWizard({
    required this.requestor,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssuerVerifierHeader(title: requestor.name.translate(lang)),
        if (state.lastNonMatchingCredential != null) ...[
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'disclosure_permission.issue_wizard.not_valid',
            style: theme.themeData.textTheme.headline3,
          ),
          SizedBox(height: theme.defaultSpacing),
          IrmaDisclosureCredentialCard(
            state.lastNonMatchingCredential!,
            style: IrmaCardStyle.error,
          )
        ],
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'disclosure_permission.issue_wizard.add_data',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.defaultSpacing),
        for (final credential in state.issueWizard) ...[
          IrmaDisclosureCredentialCard(
            credential,
            style: credential.obtained ? IrmaCardStyle.success : IrmaCardStyle.template,
          ),
        ]
      ],
    );
  }
}
