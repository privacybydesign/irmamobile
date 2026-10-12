import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../theme/theme.dart";
import "../../util/missing_data_flow.dart";
import "../../widgets/action_footer.dart";
import "../../widgets/credential_summary.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/screen_title.dart";
import "../../widgets/translated_text.dart";

const _sectionGap = 20.0;
const _stepGap = 14.0;
const _cardRadius = 10.0;
const _cardPaddingVertical = 14.0;
const _cardShadowOffset = Offset(0, 1);
const _cardShadowBlur = 6.0;
const _logoSize = 40.0;
const _badgeSize = 28.0;
const _badgeBorderWidth = 2.0;

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
    final name = credential.name.isNotEmpty
        ? credential.name
        : credential.credentialId;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        title: TranslatedText(
          "external_issuer.heads_up.app_bar",
          translationParams: {"credential": name},
          maxLines: 1,
          style: theme.textTheme.displaySmall!.copyWith(
            color: theme.dark,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: YiviBackButton(
          onTap: onBack,
          semanticsLabelKey: "external_issuer.back_to_list",
          color: theme.dark,
        ),
        bottom: context.missingDataBand,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: theme.defaultSpacing,
          vertical: theme.mediumSpacing,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: _sectionGap,
            children: [
              const ScreenTitle("external_issuer.heads_up.title"),
              _CredentialCard(credential: credential, name: name),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _stepGap,
                children: [
                  const _Step(
                    number: 1,
                    translationKey: "external_issuer.heads_up.step_1",
                  ),
                  _Step(
                    number: 2,
                    translationKey: "external_issuer.heads_up.step_2",
                    translationParams: {
                      "credential": _inSentence(context, name),
                    },
                  ),
                  const _Step(
                    number: 3,
                    translationKey: "external_issuer.heads_up.step_3",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionFooter(
        primaryLabel: "external_issuer.heads_up.to_website",
        primaryTrailingIcon: Icons.open_in_new,
        onPrimaryPressed: onOpenWebsite,
        secondaryLabel: "external_issuer.back_to_list",
        onSecondaryPressed: onBack,
      ),
    );
  }
}

/// The name as it reads in the middle of a sentence ("om je persoonsgegevens
/// toe te voegen"). German capitalises its nouns, and an acronym such as BSN
/// keeps its capitals.
String _inSentence(BuildContext context, String name) {
  final isGerman = FlutterI18n.currentLocale(context)?.languageCode == "de";
  if (isGerman || name.length < 2) return name;

  final second = name[1];
  final secondIsUpperCase =
      second == second.toUpperCase() && second != second.toLowerCase();
  if (secondIsUpperCase) return name;

  return name[0].toLowerCase() + name.substring(1);
}

class _CredentialCard extends StatelessWidget {
  final CredentialDescriptor credential;
  final String name;

  const _CredentialCard({required this.credential, required this.name});

  String? get _domain {
    final host = Uri.tryParse(credential.issueURL ?? "")?.host;
    return host == null || host.isEmpty ? null : host;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.defaultSpacing,
        vertical: _cardPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: _cardShadowOffset,
            blurRadius: _cardShadowBlur,
          ),
        ],
      ),
      child: CredentialSummary(
        name: name,
        subtitle: switch (_domain) {
          final domain? => Text(domain, style: credentialSubtitleStyle(theme)),
          null => null,
        },
        image: credential.image,
        logoSize: _logoSize,
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

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _stepGap,
        children: [
          Container(
            width: _badgeSize,
            height: _badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.light,
              shape: BoxShape.circle,
              border: Border.all(color: theme.link, width: _badgeBorderWidth),
            ),
            child: Text(
              "$number",
              style: theme.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.link,
                height: 1,
              ),
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
