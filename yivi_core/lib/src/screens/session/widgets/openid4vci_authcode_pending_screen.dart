import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/credential_card/yivi_credential_card.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/irma_quote.dart";
import "session_scaffold.dart";

class OpenID4VCIAuthCodePendingScreen extends StatelessWidget {
  final TrustedParty requestor;
  final List<CredentialDescriptor> offeredCredentialTypes;
  final VoidCallback onOpenBrowser;
  final VoidCallback onDismiss;

  const OpenID4VCIAuthCodePendingScreen({
    super.key,
    required this.requestor,
    required this.offeredCredentialTypes,
    required this.onOpenBrowser,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final issuerName = getTranslation(context, requestor.name);
    final buttonLabel = FlutterI18n.translate(
      context,
      "issuance.authorization_code.pending.open_browser",
    );

    return SessionScaffold(
      appBarTitle: "issuance.authorization_code.pending.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: buttonLabel,
        onPrimaryPressed: onOpenBrowser,
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "issuance.authorization_code.pending.cancel",
        ),
        onSecondaryPressed: onDismiss,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: theme.defaultSpacing,
          right: theme.defaultSpacing,
          top: theme.smallSpacing,
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.smallSpacing),
            child: IrmaQuote(
              quote: FlutterI18n.translate(
                context,
                "issuance.authorization_code.pending.body",
                translationParams: {
                  "issuer": issuerName,
                  "button": buttonLabel,
                },
              ),
            ),
          ),
          ...offeredCredentialTypes.map(
            (descriptor) => Padding(
              padding: EdgeInsets.only(bottom: theme.defaultSpacing),
              child: YiviCredentialCard.fromDescriptor(
                descriptor: descriptor,
                compact: false,
                hideNotObtainable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
