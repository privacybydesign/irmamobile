import "package:material_ui/material_ui.dart";

import "../models/schemaless/schemaless_events.dart";
import "../theme/theme.dart";
import "base64_image.dart";
import "irma_avatar.dart";

const _nameLineHeight = 22.0;
const _subtitleLineHeight = 20.0;

/// A credential's logo with its name and a line below it, as at the top of a
/// card on the external issuer screens.
class CredentialSummary extends StatelessWidget {
  final String name;
  final String? subtitle;
  final LogoImage? image;
  final double logoSize;

  const CredentialSummary({
    super.key,
    required this.name,
    this.subtitle,
    this.image,
    required this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final logo = image;
    final subtitle = this.subtitle;

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
                  fontWeight: FontWeight.w700,
                  height: _nameLineHeight / 16,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall!.copyWith(
                    height: _subtitleLineHeight / 14,
                    color: theme.neutralExtraDark,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
