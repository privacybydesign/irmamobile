import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../bloc/disclosure_permission_bloc.dart';
import '../bloc/disclosure_permission_state.dart';
import 'irma_template_credential_card.dart';

class IssueWizard extends StatelessWidget {
  final DisclosurePermissionBloc bloc;

  const IssueWizard(this.bloc);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final state = bloc.state as DisclosurePermissionIssueWizard;

    //TODO: Implement disclosure permission issue wizard
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IssuerVerifierHeader(title: 'Verifier name'),
        SizedBox(height: theme.defaultSpacing),
        TranslatedText(
          'Voeg de volgende gegevens toe:',
          style: theme.themeData.textTheme.headline3,
        ),
        SizedBox(height: theme.defaultSpacing),
        for (final credential in state.issueWizard) IrmaCredentialTemplateCard(credential),
      ],
    );
  }
}
