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

class OpenID4VCIAuthCodePendingScreen extends StatefulWidget {
  final TrustedParty requestor;
  final List<CredentialDescriptor> offeredCredentialTypes;
  final Future<void> Function() onOpenBrowser;
  final VoidCallback onDismiss;

  const OpenID4VCIAuthCodePendingScreen({
    super.key,
    required this.requestor,
    required this.offeredCredentialTypes,
    required this.onOpenBrowser,
    required this.onDismiss,
  });

  @override
  State<OpenID4VCIAuthCodePendingScreen> createState() =>
      _OpenID4VCIAuthCodePendingScreenState();
}

class _OpenID4VCIAuthCodePendingScreenState
    extends State<OpenID4VCIAuthCodePendingScreen> {
  bool _launching = false;

  Future<void> _handleOpenBrowser() async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      await widget.onOpenBrowser();
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final issuerName = getTranslation(context, widget.requestor.name);
    final buttonLabel = FlutterI18n.translate(
      context,
      "issuance.authorization_code.pending.open_browser",
    );

    return SessionScaffold(
      appBarTitle: "issuance.authorization_code.pending.title",
      onDismiss: widget.onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: buttonLabel,
        onPrimaryPressed: _launching ? null : _handleOpenBrowser,
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "issuance.authorization_code.pending.cancel",
        ),
        onSecondaryPressed: widget.onDismiss,
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
          ...widget.offeredCredentialTypes.map(
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
