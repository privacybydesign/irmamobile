import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../../models/session.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_bottom_bar.dart';
import '../../../../widgets/irma_progress_indicator.dart';
import '../../../../widgets/irma_quote.dart';
import '../../../../widgets/translated_text.dart';
import '../../../activity/widgets/issuer_verifier_header.dart';
import '../../widgets/session_scaffold.dart';
import '../bloc/disclosure_permission_event.dart';
import '../bloc/disclosure_permission_state.dart';
import 'disclosure_permission_share_dialog.dart';

class DisclosurePermissionChoicesScreen extends StatelessWidget {
  final RequestorInfo requestor;
  final DisclosurePermissionChoices state;
  final Function(DisclosurePermissionBlocEvent) onEvent;

  const DisclosurePermissionChoicesScreen({
    required this.requestor,
    required this.state,
    required this.onEvent,
  });

  Future<void> _showConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => DisclosurePermissionConfirmDialog(requestor: requestor),
        ) ??
        false;

    onEvent(confirmed ? DisclosurePermissionNextPressed() : DisclosurePermissionConfirmationDismissed());
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    if (state is DisclosurePermissionChoicesOverview &&
        (state as DisclosurePermissionChoicesOverview).showConfirmationPopup) {
      Future.delayed(Duration.zero, () => _showConfirmationDialog(context));
    }

    return SessionScaffold(
      appBarTitle: state is DisclosurePermissionPreviouslyAddedCredentialsOverview
          ? 'disclosure_permission.previously_added.title'
          : 'disclosure_permission.overview.title',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IssuerVerifierHeader(title: requestor.name.translate(lang)),
            if (state.plannedSteps.length > 1)
              IrmaProgressIndicator(
                step: state.currentStepIndex + 1,
                stepCount: state.plannedSteps.length,
              ),
            SizedBox(height: theme.defaultSpacing),
            IrmaQuote(
              richQuote: RichText(
                text: TextSpan(
                  children: [
                    if (state.plannedSteps.length > 1)
                      TextSpan(
                        text: '${FlutterI18n.translate(context, 'ui.step')} ${state.currentStepIndex + 1}: ',
                        style: theme.themeData.textTheme.caption!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    TextSpan(
                      text: state is DisclosurePermissionPreviouslyAddedCredentialsOverview
                          ? FlutterI18n.translate(context, 'disclosure_permission.previously_added.explanation')
                          : FlutterI18n.translate(
                              context,
                              'disclosure_permission.overview.explanation',
                              translationParams: {
                                'requestorName': requestor.name.translate(lang),
                              },
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
              state is DisclosurePermissionPreviouslyAddedCredentialsOverview
                  ? 'disclosure_permission.previously_added.header'
                  : 'disclosure_permission.overview.header',
              style: theme.themeData.textTheme.headline3,
            ),
            SizedBox(height: theme.smallSpacing),
            ...state.choices.entries
                .map(
                  (choiceEntry) => Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => onEvent(DisclosurePermissionChangeChoicePressed(disconIndex: choiceEntry.key)),
                            child: TranslatedText(
                              'disclosure_permission.change_choice',
                              style: theme.textTheme.caption!.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: theme.smallSpacing),
                      for (var credential in choiceEntry.value)
                        IrmaCredentialCard(
                          credentialInfo: credential,
                          attributes: credential.attributes,
                        )
                    ],
                  ),
                )
                .toList()
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: state is DisclosurePermissionPreviouslyAddedCredentialsOverview
            ? 'disclosure_permission.next_step'
            : 'disclosure_permission.overview.confirm',
        onPrimaryPressed: () => onEvent(
          DisclosurePermissionNextPressed(),
        ),
      ),
    );
  }
}
