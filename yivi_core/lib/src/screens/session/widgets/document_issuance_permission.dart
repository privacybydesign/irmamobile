import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/models/credential_card_layout.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_icon_button.dart";
import "../../../widgets/translated_text.dart";

/// The permission screen for a document read from its chip, with
/// FeatureFlag.documentFlowV2 on: the document's card on the light blue page,
/// and a footer with the choice.
class DocumentIssuancePermission extends StatelessWidget {
  const DocumentIssuancePermission({
    required this.issuedCredentials,
    this.onDismiss,
    this.onGivePermission,
    this.returnedFromIssuer,
    super.key,
  });

  static const double _closeIconSize = 22;

  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  /// Name of the issuer whose website the user just came back from, if any.
  final String? returnedFromIssuer;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: "issuance.title",
        leading: null,
        hasBorder: false,
        actions: [
          if (onDismiss != null)
            Padding(
              padding: .only(right: theme.tinySpacing),
              child: IrmaIconButton(
                icon: Icons.close,
                size: _closeIconSize,
                semanticsLabelKey: "accessibility.close",
                onTap: onDismiss!,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: .all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: theme.defaultSpacing,
          children: [
            if (returnedFromIssuer != null)
              TranslatedText(
                "external_issuer.returned",
                translationParams: {"issuer": returnedFromIssuer!},
                style: theme.textTheme.headlineMedium,
              ),
            Container(
              padding: .symmetric(
                horizontal: theme.defaultSpacing,
                vertical: theme.smallSpacing + theme.tinySpacing,
              ),
              decoration: BoxDecoration(
                color: theme.tertiary,
                borderRadius: theme.borderRadius,
              ),
              child: const TranslatedText("issuance.description"),
            ),
            for (final credential in issuedCredentials)
              YiviCredentialCard.fromCredential(
                credential: credential,
                compact: false,
                lowInstanceCountThreshold: 0,
                layout: CredentialCardLayout.document,
              ),
          ],
        ),
      ),
      bottomNavigationBar: DocumentFlowFooter(
        buttons: onGivePermission != null
            ? [
                DocumentFlowButton(
                  key: DocumentFlowButton.primaryKey,
                  labelKey: "issuance.add",
                  onPressed: onGivePermission,
                ),
                DocumentFlowButton(
                  key: DocumentFlowButton.secondaryKey,
                  labelKey: "document_flow.cancel",
                  onPressed: onDismiss,
                  style: .text,
                ),
              ]
            : [
                DocumentFlowButton(
                  key: DocumentFlowButton.primaryKey,
                  labelKey: "session.navigation_bar.back",
                  onPressed: onDismiss,
                ),
              ],
      ),
    );
  }
}
