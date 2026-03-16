import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "session_scaffold.dart";

class OpenId4VciIssuancePermission extends StatelessWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.CredentialDescriptor> issuedCredentials;

  const OpenId4VciIssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
    required this.issuedCredentials,
  });

  @override
  Widget build(BuildContext context) => SessionScaffold(
    appBarTitle: "issuance.title",
    bottomNavigationBar: _buildNavigationBar(context),
    body: _buildBody(context),
    onDismiss: onDismiss,
  );

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
            padding: EdgeInsets.only(bottom: theme.defaultSpacing),
            child: YiviCredentialCard.fromDescriptorWithEmptyAttributeValues(
              descriptor: credential,
              compact: true,
            ),
          ),
        ),
      ],
    );
  }
}
