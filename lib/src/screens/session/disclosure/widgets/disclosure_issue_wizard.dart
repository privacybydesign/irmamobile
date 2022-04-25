import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'irma_template_credential_card.dart';

class DisclosureIssueWizard extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionIssueWizard state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosureIssueWizard({
    required this.requestor,
    required this.state,
    required this.onEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IssuerVerifierHeader(title: requestor.name.translate(lang)),
              SizedBox(height: theme.defaultSpacing),
              TranslatedText(
                'disclosure_permission.issue_wizard.add_data',
                style: theme.themeData.textTheme.headline3,
              ),
              SizedBox(height: theme.defaultSpacing),
              for (final credential in state.issueWizard) IrmaCredentialTemplateCard(credential),
            ],
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: IrmaBottomBar(
              primaryButtonLabel: 'disclosure_permission.next',
              onPrimaryPressed: state.completed ? () => onEvent(DisclosurePermissionNextPressed()) : null,
            ))
      ],
    );
  }
}
