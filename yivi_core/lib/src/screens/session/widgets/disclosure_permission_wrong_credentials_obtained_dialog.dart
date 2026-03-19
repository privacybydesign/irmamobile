import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_dialog.dart";
import "../../../widgets/yivi_themed_button.dart";

/// Dialog shown when the user obtains credentials that don't match
/// the specific attribute values requested in the disclosure session.
class DisclosurePermissionWrongCredentialsAddedDialog extends StatelessWidget {
  final Credential wrongCredential;
  final CredentialDescriptor template;
  final VoidCallback onDismiss;

  const DisclosurePermissionWrongCredentialsAddedDialog({
    super.key,
    required this.wrongCredential,
    required this.template,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // Build compareTo list: attributes with value constraints from the template,
    // using the requested value as the "expected" value for comparison.
    final compareTo = template.attributes
        .where(
          (a) => a.requestedValue != null && a.requestedValue!.hasConcreteValue,
        )
        .map(
          (a) => Attribute(
            id: a.id,
            displayName: a.displayName,
            description: a.description,
            value: a.requestedValue,
          ),
        )
        .toList();

    return IrmaDialog(
      title: FlutterI18n.translate(
        context,
        "disclosure_permission.wrong_credentials_added.title",
      ),
      content: FlutterI18n.translate(
        context,
        "disclosure_permission.wrong_credentials_added.explanation",
      ),
      child: Column(
        children: [
          // Show obtained credential with wrong values, compared to expected
          YiviCredentialCard.fromCredential(
            credential: wrongCredential,
            compact: true,
            hideFooter: true,
            compareTo: compareTo,
          ),
          // Show template card with the expected values
          YiviCredentialCard.fromDescriptor(
            descriptor: template,
            compact: true,
          ),
          SizedBox(height: theme.defaultSpacing),
          YiviThemedButton(
            label:
                "disclosure_permission.wrong_credentials_added.dismiss_action",
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
