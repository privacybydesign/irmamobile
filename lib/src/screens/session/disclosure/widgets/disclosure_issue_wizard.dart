import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../bloc/disclosure_permission_state.dart';

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
    final firstMismatchIndex = state.obtainedCredentialsMatch.indexWhere((obt) => !obt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssuerVerifierHeader(title: requestor.name.translate(lang)),
        if (firstMismatchIndex >= 0 && state.obtainedCredentials[firstMismatchIndex] != null) ...[
          SizedBox(height: theme.defaultSpacing),
          TranslatedText(
            'disclosure_permission.issue_wizard.not_valid',
            style: theme.themeData.textTheme.headline3,
          ),
          SizedBox(height: theme.defaultSpacing),
          IrmaCredentialsCard.fromCredentialInfo(
            credentialInfo: state.obtainedCredentials[firstMismatchIndex]!,
            style: IrmaCardStyle.error,
            attributes: state.obtainedCredentials[firstMismatchIndex]!.attributes,
            // Because the added credential does not match the requested template credential
            // compare the two to show which attributes match and which do not.
            compareTo: state.issueWizard[firstMismatchIndex],
          )
        ],
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'disclosure_permission.issue_wizard.add_data',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.defaultSpacing),
        ...state.issueWizard.mapIndexed(
          (i, cred) => IrmaCredentialsCard.fromCredentialInfo(
            credentialInfo: cred,
            attributes: cred.attributes,
            compareTo: cred,
            style: state.obtainedCredentialsMatch[i] ? IrmaCardStyle.success : IrmaCardStyle.template,
            onTap: () => throw UnimplementedError(),
          ),
        ),
      ],
    );
  }
}
