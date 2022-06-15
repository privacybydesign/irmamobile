import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/irma_progress_indicator.dart';
import '../../../../widgets/irma_quote.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_state.dart';

class DisclosurePreviouslyAddedScreen extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionPreviouslyAddedCredentialsOverview state;

  const DisclosurePreviouslyAddedScreen({
    required this.requestor,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return SessionScaffold(
      appBarTitle: 'disclosure_permission.issue_wizard.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          children: [
            IssuerVerifierHeader(title: requestor.name.translate(lang)),
            IrmaProgressIndicator(
              step: state.currentStepIndex + 1,
              stepCount: state.plannedSteps.length,
            ),
            SizedBox(height: theme.defaultSpacing),
            IrmaQuote(
              richQuote: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${FlutterI18n.translate(context, 'ui.step')} ${state.currentStepIndex + 1}: ',
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
          ],
        ),
      ),
    );
  }
}
