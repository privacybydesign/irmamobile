import "dart:io";

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

    return YiviDialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ColoredBox(
          color: theme.backgroundTertiary,
          child: Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Semantics(
                        namesRoute: !Platform.isIOS,
                        label: FlutterI18n.translate(
                          context,
                          "accessibility.alert",
                        ),
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "disclosure_permission.wrong_credentials_added.title",
                          ),
                          style: theme.textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: theme.mediumSpacing),
                      Text(
                        FlutterI18n.translate(
                          context,
                          "disclosure_permission.wrong_credentials_added.explanation",
                        ),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: theme.defaultSpacing),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "disclosure_permission.wrong_credentials_added.you_issued",
                          ),
                          style: theme.themeData.textTheme.headlineMedium,
                        ),
                      ),
                      SizedBox(height: theme.smallSpacing),
                      YiviCredentialCard.fromCredential(
                        credential: wrongCredential,
                        compact: true,
                        hideFooter: true,
                        compareTo: compareTo,
                      ),
                      SizedBox(height: theme.defaultSpacing),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "disclosure_permission.wrong_credentials_added.expected",
                          ),
                          style: theme.themeData.textTheme.headlineMedium,
                        ),
                      ),
                      SizedBox(height: theme.smallSpacing),
                      YiviCredentialCard.fromDescriptor(
                        descriptor: template,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: theme.defaultSpacing),
                YiviThemedButton(
                  label:
                      "disclosure_permission.wrong_credentials_added.dismiss_action",
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
