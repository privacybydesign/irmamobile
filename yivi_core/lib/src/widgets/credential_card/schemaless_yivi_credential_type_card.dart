import "package:flutter/material.dart";

import "../../models/translated_value.dart";
import "../../theme/theme.dart";
import "../../util/language.dart";
import "../irma_avatar.dart";
import "../irma_card.dart";

class SchemalessYiviCredentialTypeCard extends StatelessWidget {
  final String credentialImagePath;
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
    required this.credentialImagePath,
    required this.credentialName,
    required this.credentialId,
    required this.issuerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    const logoContainerSize = 52.0;

    Widget avatar = IrmaAvatar(
      size: logoContainerSize,
      logoPath: credentialImagePath,
      initials: "DM",
    );

    // If the credential is checked, add a check mark to the avatar
    if (checked) {
      avatar = Stack(
        alignment: Alignment.topRight,
        children: [
          avatar,
          Icon(
            Icons.check_circle,
            color: theme.success,
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
            padding: EdgeInsets.all(theme.defaultSpacing),
            child: Row(
              children: [
                ExcludeSemantics(child: avatar),
                SizedBox(width: theme.defaultSpacing - theme.tinySpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslation(context, credentialName),
                        style: theme.textTheme.headlineMedium!.copyWith(
                          color: theme.dark,
                        ),
                      ),
                      SizedBox(height: theme.tinySpacing),
                      Text(
                        getTranslation(context, issuerName),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: theme.smallSpacing),
                Icon(
                  trailingIcon ?? Icons.chevron_right,
                  size: 24,
                  color: theme.neutralExtraDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
