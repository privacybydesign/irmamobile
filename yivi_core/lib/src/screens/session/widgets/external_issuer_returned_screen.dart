import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "../../../widgets/action_footer.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/credential_summary.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/screen_title.dart";
import "../../../widgets/translated_text.dart";
import "external_issuer_return_notice.dart";

const _logoSize = 44.0;
const _attributesPaddingVertical = 10.0;

/// The issuance confirmation for a user who just came back from the issuer's
/// website, which they opened from the app.
class ExternalIssuerReturnedScreen extends StatelessWidget {
  final List<schemaless.Credential> credentials;

  /// The credential whose website the user opened.
  final schemaless.Credential returnedFrom;
  final VoidCallback? onAdd;
  final VoidCallback? onBack;

  const ExternalIssuerReturnedScreen({
    super.key,
    required this.credentials,
    required this.returnedFrom,
    this.onAdd,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        title: TranslatedText(
          "external_issuer.heads_up.app_bar",
          translationParams: {"credential": returnedFrom.name},
          maxLines: 1,
          style: theme.textTheme.displaySmall!.copyWith(
            color: theme.dark,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.defaultSpacing,
            children: [
              ExternalIssuerReturnNotice(issuer: returnedFrom.issuer.name),
              const ScreenTitle("issuance.description"),
              for (final credential in credentials)
                _CredentialCard(credential: credential),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionFooter(
        primaryLabel: "ui.add",
        onPrimaryPressed: onAdd,
        secondaryLabel: "external_issuer.back_to_list",
        onSecondaryPressed: onBack,
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final schemaless.Credential credential;

  const _CredentialCard({required this.credential});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: theme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(theme.defaultSpacing),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.neutralExtraLight),
              ),
            ),
            child: CredentialSummary(
              name: credential.name,
              subtitle: Text(
                credential.issuer.name,
                style: credentialSubtitleStyle(theme),
              ),
              image: credential.image,
              logoSize: _logoSize,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.defaultSpacing,
              vertical: _attributesPaddingVertical,
            ),
            child: YiviCredentialCardAttributeList(credential.attributes),
          ),
        ],
      ),
    );
  }
}
