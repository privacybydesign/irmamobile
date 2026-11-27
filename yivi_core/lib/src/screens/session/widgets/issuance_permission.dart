import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../../util/nfc_credentials.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "document_issuance_permission.dart";
import "session_scaffold.dart";

class IssuancePermission extends StatelessWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  const IssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
    required this.issuedCredentials,
  });

  @override
  Widget build(BuildContext context) {
    // A document read from its chip gets its own screen.
    final isDocument =
        issuedCredentials.isNotEmpty &&
        issuedCredentials.every((c) => credentialRequiresNfc(c.credentialId));
    if (isDocument) {
      return DocumentIssuancePermission(
        issuedCredentials: issuedCredentials,
        onDismiss: onDismiss,
        onGivePermission: onGivePermission,
      );
    }

    return SessionScaffold(
      appBarTitle: "issuance.title",
      bottomNavigationBar: _buildNavigationBar(context),
      body: _buildBody(context),
      onDismiss: onDismiss,
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return onGivePermission != null
        ? IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(context, "issuance.add"),
            onPrimaryPressed: () => onGivePermission?.call(),
            secondaryButtonLabel: FlutterI18n.translate(
              context,
              "issuance.cancel",
            ),
            onSecondaryPressed: () => onDismiss?.call(),
          )
        : IrmaBottomBar(
            primaryButtonLabel: FlutterI18n.translate(
              context,
              "session.navigation_bar.back",
            ),
            onPrimaryPressed: () => onDismiss?.call(),
          );
  }

  Widget _buildBody(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
          child: IrmaQuote(
            quote: FlutterI18n.translate(context, "issuance.description"),
          ),
        ),
        ...issuedCredentials.map(
          (credential) => Padding(
            padding: EdgeInsets.only(bottom: theme.smallSpacing),
            child: YiviCredentialCard.fromCredential(
              credential: credential,
              compact: false,
              lowInstanceCountThreshold: 0,
            ),
          ),
        ),
      ],
    );
  }
}
