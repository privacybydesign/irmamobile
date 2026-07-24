import "package:flutter/material.dart";

import "../../theme/theme.dart";
import "../chevron.dart";
import "../irma_avatar.dart";
import "../irma_card.dart";

class SchemalessYiviCredentialTypeCard extends StatelessWidget {
  final String? credentialImagePath;
  final Widget? credentialImageBase64;
  final String credentialName;
  final String credentialId;
  final String issuerName;

  final VoidCallback? onTap;
  final bool checked;
  final IconData? trailingIcon;

  /// Whether the credential is shown greyed out (e.g. it requires onboard NFC
  /// but the device has no NFC hardware). The card stays tappable so [onTap]
  /// can explain why it is unavailable.
  final bool disabled;

  /// Localised explanation announced by assistive technology when [disabled] is
  /// set (e.g. "requires NFC, which this device does not support"). Conveying
  /// the reason this way means the unavailable state is not communicated by the
  /// dimmed appearance alone.
  final String? disabledHint;

  const SchemalessYiviCredentialTypeCard({
    this.onTap,
    this.checked = false,
    this.trailingIcon,
    this.disabled = false,
    this.disabledHint,
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
              credentialName.isNotEmpty
          ? credentialName[0]
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

    // Greyed-out credentials dim the avatar and trailing icon for a clear
    // "unavailable" look, while the title/issuer text keeps an AA-compliant
    // muted colour (not a blanket opacity, which would drop the text below the
    // 4.5:1 contrast minimum on a still-interactive control).
    if (disabled) {
      avatar = Opacity(opacity: 0.4, child: avatar);
    }
    final Color titleColor = disabled ? theme.neutralDark : theme.dark;
    final Color issuerColor = disabled
        ? theme.neutralDark
        : theme.neutralExtraDark;
    final Color trailingColor = disabled
        ? theme.neutral
        : theme.neutralExtraDark;

    return Semantics(
      enabled: !disabled,
      hint: disabled ? disabledHint : null,
      child: IrmaCard(
        margin: EdgeInsets.zero,
        child: Material(
          child: InkWell(
            key: Key("${credentialId}_tile"),
            onTap: onTap,
            // Greyed-out credentials stay tappable so onTap can explain why they
            // are unavailable.
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
                          credentialName,
                          style: theme.themeData.textTheme.headlineMedium!
                              .copyWith(fontSize: 16, color: titleColor),
                        ),
                        Text(
                          issuerName,
                          style: theme.themeData.textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            color: issuerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: theme.smallSpacing),
                  if (trailingIcon != null)
                    Icon(trailingIcon, size: 24, color: trailingColor)
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
