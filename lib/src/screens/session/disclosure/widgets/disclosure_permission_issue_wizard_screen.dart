import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../theme/theme.dart';
import '../../../../widgets/irma_progress_indicator.dart';
import '../../../../widgets/irma_quote.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_issue_wizard_stepper.dart';

class DisclosurePermissionIssueWizardScreen extends StatelessWidget {
  final DisclosurePermissionIssueWizard state;

  const DisclosurePermissionIssueWizardScreen({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //TODO: Add dynamic header title
            const IssuerVerifierHeader(title: 'Gemeente Amsterdam'),
            const IrmaProgressIndicator(
              step: 1,
              stepCount: 3,
            ),
            SizedBox(height: theme.defaultSpacing),
            IrmaQuote(
              richQuote: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${FlutterI18n.translate(context, 'ui.step')} 1: ',
                      style: theme.themeData.textTheme.caption!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: FlutterI18n.translate(
                        context,
                        'disclosure_permission.issue_wizard.explanation',
                      ),
                      style: theme.themeData.textTheme.caption,
                    ),
                  ],
                ),
              ),
              color: theme.lightBeige,
            ),
            SizedBox(height: theme.defaultSpacing),
            TranslatedText(
              'disclosure_permission.issue_wizard.add_data',
              style: theme.themeData.textTheme.headline3,
            ),
            SizedBox(height: theme.defaultSpacing),
            // TODO Implement the refactored stepper
            // DisclosureIssueWizardStepper(
            //   issueWizardChoices: state.issueWizardChoices,
            // ),
          ],
        ),
      ),
    );
  }
}
