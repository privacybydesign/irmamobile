import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../../util/missing_data_flow.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/irma_divider.dart";
import "../../../widgets/missing_data_bottom_bar.dart";
import "../../../widgets/missing_data_style.dart";

const _logoSize = 44.0;

/// The step where the user confirms adding what they just obtained, shown
/// instead of [IssuancePermission] while they are collecting data for a
/// request (`FeatureFlag.missingDataChecklist`). Leaving it leads back to the
/// checklist.
class MissingDataConfirmScreen extends StatelessWidget {
  final List<schemaless.Credential> issuedCredentials;
  final VoidCallback onDismiss;
  final VoidCallback onGivePermission;

  const MissingDataConfirmScreen({
    super.key,
    required this.issuedCredentials,
    required this.onDismiss,
    required this.onGivePermission,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final missingData = context.missingDataState;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: context.issuanceAppBar(
        titleKey: "issuance.title",
        onBack: onDismiss,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: theme.defaultSpacing,
            vertical: theme.mediumSpacing,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.defaultSpacing,
            children: [
              Semantics(
                header: true,
                child: Text(
                  FlutterI18n.translate(
                    context,
                    issuedCredentials.length == 1
                        ? "missing_data.confirm.one"
                        : "missing_data.confirm.other",
                  ),
                  style: missingDataHeadingStyle(theme),
                ),
              ),
              for (final credential in issuedCredentials)
                _ConfirmCard(credential: credential),
              if (missingData != null)
                Text(
                  FlutterI18n.translate(
                    context,
                    "missing_data.confirm.after",
                    translationParams: {"requestor": missingData.requestorName},
                  ),
                  style: missingDataCaptionStyle(theme),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MissingDataBottomBar.buttons(
        primaryButtonLabel: "missing_data.confirm.add",
        onPrimaryPressed: onGivePermission,
        secondaryButtonLabel: "missing_data.back_to_list",
        onSecondaryPressed: onDismiss,
      ),
    );
  }
}

/// The credential about to be added: who issues it, and what it says.
class _ConfirmCard extends StatelessWidget {
  final schemaless.Credential credential;

  const _ConfirmCard({required this.credential});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final image = credential.image;

    return IrmaCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Row(
              spacing: 12,
              children: [
                ExcludeSemantics(
                  child: IrmaAvatar(
                    size: _logoSize,
                    logoImage: image != null
                        ? Base64Image(
                            base64: image.base64,
                            mimeType: image.mimeType,
                          )
                        : null,
                    initials: credential.name.isNotEmpty
                        ? credential.name[0]
                        : "?",
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.name,
                        style: missingDataNameStyle(
                          theme,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        credential.issuer.name,
                        style: missingDataCaptionStyle(theme),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (credential.attributes.isNotEmpty) ...[
            const IrmaDivider(),
            Padding(
              // The attribute list has a small padding of its own.
              padding: EdgeInsets.fromLTRB(
                theme.defaultSpacing,
                theme.smallSpacing,
                theme.defaultSpacing,
                12,
              ),
              child: YiviCredentialCardAttributeList(credential.attributes),
            ),
          ],
        ],
      ),
    );
  }
}
