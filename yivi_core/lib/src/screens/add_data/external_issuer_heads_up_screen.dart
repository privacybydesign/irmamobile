import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../theme/theme.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/yivi_credential_card_header.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_avatar.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/irma_card.dart";
import "../../widgets/irma_step_indicator.dart";
import "../../widgets/translated_text.dart";

/// Tells the user they are about to leave Yivi for the issuer's website.
/// Replaces the add-data details page for credentials issued on a website.
class ExternalIssuerHeadsUpScreen extends StatelessWidget {
  final CredentialDescriptor credential;
  final VoidCallback onOpenWebsite;
  final VoidCallback onBack;

  const ExternalIssuerHeadsUpScreen({
    super.key,
    required this.credential,
    required this.onOpenWebsite,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final image = credential.image;
    final name = credential.name.isNotEmpty
        ? credential.name
        : credential.credentialId;
    final domain = Uri.tryParse(credential.issueURL ?? "")?.host;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: "data.add.details.title",
        leading: YiviBackButton(onTap: onBack),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.defaultSpacing,
            children: [
              TranslatedText(
                "external_issuer.heads_up.title",
                style: theme.textTheme.headlineMedium,
              ),
              IrmaCard(
                child: Row(
                  spacing: theme.smallSpacing + theme.tinySpacing,
                  children: [
                    ExcludeSemantics(
                      child: IrmaAvatar(
                        size: 52,
                        logoImage: image != null
                            ? Base64Image(
                                base64: image.base64,
                                mimeType: image.mimeType,
                              )
                            : null,
                        initials: image == null ? name[0] : null,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: credentialNameStyle(theme, 19)),
                          if (domain != null && domain.isNotEmpty)
                            Text(domain, style: issuerLabelStyle(theme)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _Step(
                number: 1,
                translationKey: "external_issuer.heads_up.step_1",
              ),
              _Step(
                number: 2,
                translationKey: "external_issuer.heads_up.step_2",
                translationParams: {"credential": name},
              ),
              _Step(
                number: 3,
                translationKey: "external_issuer.heads_up.step_3",
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "external_issuer.heads_up.to_website",
        primaryButtonTrailingIcon: Icons.open_in_new,
        onPrimaryPressed: onOpenWebsite,
        secondaryButtonLabel: "external_issuer.heads_up.back_to_list",
        onSecondaryPressed: onBack,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String translationKey;
  final Map<String, String>? translationParams;

  const _Step({
    required this.number,
    required this.translationKey,
    this.translationParams,
  });

  static const _badgeSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.smallSpacing + theme.tinySpacing,
        children: [
          SizedBox.square(
            dimension: _badgeSize,
            child: IrmaStepIndicator(
              step: number,
              style: IrmaStepIndicatorStyle.outlined,
            ),
          ),
          Expanded(
            child: TranslatedText(
              translationKey,
              translationParams: translationParams,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
