import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/translated_text.dart";
import "session_scaffold.dart";

class OpenID4VCIAuthCodePendingScreen extends StatelessWidget {
  final TrustedParty issuer;
  final VoidCallback onOpenBrowser;
  final VoidCallback onDismiss;

  const OpenID4VCIAuthCodePendingScreen({
    super.key,
    required this.issuer,
    required this.onOpenBrowser,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final issuerName = getTranslation(context, issuer.name);

    return SessionScaffold(
      appBarTitle: "issuance.authorization_code.pending.title",
      onDismiss: onDismiss,
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(
          context,
          "issuance.authorization_code.pending.open_browser",
        ),
        onPrimaryPressed: onOpenBrowser,
        secondaryButtonLabel: FlutterI18n.translate(
          context,
          "issuance.authorization_code.pending.cancel",
        ),
        onSecondaryPressed: onDismiss,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: theme.defaultSpacing),
              TranslatedText(
                "issuance.authorization_code.pending.header",
                isHeader: true,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.neutralExtraDark,
                ),
              ),
              SizedBox(height: theme.defaultSpacing),
              TranslatedText(
                "issuance.authorization_code.pending.body",
                translationParams: {"issuer": issuerName},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
