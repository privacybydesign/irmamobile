import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "irma_avatar.dart";
import "translated_text.dart";

const _nameLineHeight = 22.0;
const _subtitleLineHeight = 20.0;

/// The line below a credential name.
TextStyle credentialSubtitleStyle(IrmaThemeData theme) => theme
    .textTheme
    .bodySmall!
    .copyWith(height: _subtitleLineHeight / 14, color: theme.neutralExtraDark);

const _waitingColor = Color(0xFF7A4B00);

/// "Not received yet", for a credential whose website the user opened and came
/// back from without finishing. Announced when it appears.
class ExternalIssuerWaitingStatus extends StatelessWidget {
  const ExternalIssuerWaitingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Semantics(
      liveRegion: true,
      child: TranslatedText(
        "external_issuer.waiting.status",
        style: credentialSubtitleStyle(
          theme,
        ).copyWith(fontWeight: FontWeight.w600, color: _waitingColor),
      ),
    );
  }
}

/// A credential's logo with its name and a line below it, as at the top of a
/// card on the external issuer screens.
class CredentialSummary extends StatelessWidget {
  final String name;
  final FontWeight nameWeight;
  final Widget? subtitle;
  final LogoImage? image;
  final double logoSize;

  const CredentialSummary({
    super.key,
    required this.name,
    this.nameWeight = FontWeight.w700,
    this.subtitle,
    this.image,
    required this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final logo = image;

    return Row(
      spacing: theme.smallSpacing + theme.tinySpacing,
      children: [
        ExcludeSemantics(
          child: IrmaAvatar(
            size: logoSize,
            logoImage: logo != null
                ? Base64Image(base64: logo.base64, mimeType: logo.mimeType)
                : null,
            initials: logo == null ? (name.isEmpty ? "?" : name[0]) : null,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: nameWeight,
                  height: _nameLineHeight / 16,
                ),
              ),
              ?subtitle,
            ],
          ),
        ),
      ],
    );
  }
}
