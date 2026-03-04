import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "session_scaffold.dart";

/// Shows the issuance-during-disclosure steps that the user needs to complete
/// before they can proceed with the disclosure.
///
/// This widget is purely presentational — it displays the current state of
/// the issuance steps as provided by [sessionState.disclosurePlan.issueDuringDislosure].
/// When Go detects that all steps are complete, it will update the session state
/// and this widget will no longer be shown.
class SchemalessIssueDuringDisclosure extends StatelessWidget {
  final SessionState sessionState;
  final VoidCallback onDismiss;

  const SchemalessIssueDuringDisclosure({
    super.key,
    required this.sessionState,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final steps = sessionState.disclosurePlan!.issueDuringDislosure!.steps;
    final requestorName = sessionState.requestor.name.translate(lang);

    return SessionScaffold(
      appBarTitle: "disclosure.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "session.navigation_bar.cancel",
        ),
        onSecondaryPressed: onDismiss,
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        children: [
          IrmaQuote(
            quote: FlutterI18n.translate(
              context,
              "disclosure.issue_during_disclosure.instruction",
              translationParams: {"requestor": requestorName},
            ),
          ),
          SizedBox(height: theme.defaultSpacing),
          for (final (index, step) in steps.indexed)
            _IssuanceStepCard(step: step, stepNumber: index + 1),
        ],
      ),
    );
  }
}

class _IssuanceStepCard extends StatelessWidget {
  final IssuanceStep step;
  final int stepNumber;

  const _IssuanceStepCard({required this.step, required this.stepNumber});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: theme.smallSpacing),
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlutterI18n.translate(
                context,
                "disclosure.issue_during_disclosure.step",
                translationParams: {"step": "$stepNumber"},
              ),
              style: theme.themeData.textTheme.titleMedium,
            ),
            SizedBox(height: theme.smallSpacing),
            for (final option in step.options)
              _CredentialOptionTile(credential: option),
          ],
        ),
      ),
    );
  }
}

class _CredentialOptionTile extends StatelessWidget {
  final CredentialDescriptor credential;

  const _CredentialOptionTile({required this.credential});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
      child: Row(
        children: [
          if (credential.imagePath.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: theme.smallSpacing),
              child: Image.asset(
                credential.imagePath,
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 40, height: 40),
              ),
            ),
          Expanded(
            child: Text(
              getTranslation(context, credential.name),
              style: theme.themeData.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
