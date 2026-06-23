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

  /// Whether the credential is shown greyed out (e.g. it requires onboard NFC
  /// but the device has no NFC hardware). The card stays tappable so [onTap]
  /// can explain why it is unavailable.
  final bool disabled;

  const SchemalessYiviCredentialTypeCard({
    this.onTap,
    this.checked = false,
    this.trailingIcon,
    this.disabled = false,
    this.credentialImagePath,
    this.credentialImageBase64,
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
          // Greyed-out credentials stay tappable (so onTap can explain why they
          // are unavailable) but are visually dimmed.
          child: Opacity(
            opacity: disabled ? 0.4 : 1.0,
            child: Padding(
              // Tighter right padding when showing the default chevron so it
              // sits closer to the card edge. Action icons (e.g. the `+` on the
              // add-data screen) keep the standard padding.
              padding: trailingIcon == null
                  ? EdgeInsets.fromLTRB(
                      theme.defaultSpacing,
                      theme.defaultSpacing,
                      theme.smallSpacing,
                      theme.defaultSpacing,
                    )
                  : EdgeInsets.all(theme.defaultSpacing),
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
                          style: theme.themeData.textTheme.headlineMedium!
                              .copyWith(fontSize: 16, color: theme.dark),
                        ),
                        Text(
                          getTranslation(context, issuerName),
                          style: theme.themeData.textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            color: theme.neutralExtraDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: theme.smallSpacing),
                  if (trailingIcon != null)
                    Icon(trailingIcon, size: 24, color: theme.neutralExtraDark)
                  else
                    const Chevron(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
