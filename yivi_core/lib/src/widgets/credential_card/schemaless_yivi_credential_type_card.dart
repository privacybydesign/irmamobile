import "package:flutter/material.dart";

import "../../models/translated_value.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../chevron.dart";
import "../irma_avatar.dart";
import "../irma_card.dart";

class SchemalessYiviCredentialTypeCard extends StatelessWidget {
  final String? credentialImagePath;
  final Widget? credentialImageBase64;
  final TranslatedValue credentialName;
  final String credentialId;
  final TranslatedValue issuerName;

  final VoidCallback? onTap;
  final bool checked;
  final IconData? trailingIcon;

  const SchemalessYiviCredentialTypeCard({
    this.onTap,
    this.checked = false,
    this.trailingIcon,
    this.credentialImagePath,
    this.credentialImageBase64,
    required this.credentialName,
    required this.credentialId,
    required this.issuerName,
  });

  @override
  Widget build(BuildContext context) {
    const logoContainerSize = 52.0;

    Widget avatar = IrmaAvatar(
      size: logoContainerSize,
      logoImage: credentialImageBase64,
      logoPath: credentialImagePath,
      initials:
          credentialImagePath == null &&
              credentialImageBase64 == null &&
              getTranslation(context, credentialName).isNotEmpty
          ? getTranslation(context, credentialName)[0]
          : null,
    );

    // If the credential is checked, add a check mark to the avatar
    if (checked) {
      avatar = Stack(
        alignment: Alignment.topRight,
        children: [
          avatar,
          Icon(
            Icons.check_circle,
            color: context.yivi.brand.success,
            size: logoContainerSize * 0.3,
          ),
        ],
      );
    }

    return IrmaCard(
      margin: EdgeInsets.zero,
      child: Material(
        child: InkWell(
          key: Key("${credentialId}_tile"),
          onTap: onTap,
          child: Padding(
            // Tighter right padding when showing the default chevron so it
            // sits closer to the card edge. Action icons (e.g. the `+` on the
            // add-data screen) keep the standard padding.
            padding: trailingIcon == null
                ? EdgeInsets.fromLTRB(
                    context.yivi.spacing.base,
                    context.yivi.spacing.base,
                    context.yivi.spacing.small,
                    context.yivi.spacing.base,
                  )
                : EdgeInsets.all(context.yivi.spacing.base),
            child: Row(
              children: [
                ExcludeSemantics(child: avatar),
                SizedBox(
                  width: context.yivi.spacing.base - context.yivi.spacing.tiny,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslation(context, credentialName),
                        style: context.text.titleMedium,
                      ),
                      Text(
                        getTranslation(context, issuerName),
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.yivi.spacing.small),
                if (trailingIcon != null)
                  Icon(
                    trailingIcon,
                    size: 24,
                    color: context.colors.onSurfaceVariant,
                  )
                else
                  const Chevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
