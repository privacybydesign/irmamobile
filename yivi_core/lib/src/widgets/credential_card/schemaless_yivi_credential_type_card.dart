import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../chevron.dart";
import "../irma_avatar.dart";
import "../irma_card.dart";
import "models/credential_card_status.dart";

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

  /// [ExpireState.expired] fades the card, puts a badge on the logo and shows
  /// "Expired" in place of the issuer name. The other states look like
  /// [ExpireState.notExpired].
  final ExpireState expireState;

  const SchemalessYiviCredentialTypeCard({
    this.onTap,
    this.checked = false,
    this.trailingIcon,
    this.disabled = false,
    this.disabledHint,
    this.expireState = ExpireState.notExpired,
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
    final bool expired = expireState == ExpireState.expired;

    final bool hasImage =
        credentialImagePath != null || credentialImageBase64 != null;
    // When there is no logo, IrmaAvatar requires initials. Prefer the credential
    // name, fall back to the issuer name, and finally to a neutral glyph so a
    // credential that arrives without a resolvable display name (e.g. an issuer
    // whose OID4VCI credential display irmago could not parse) still renders
    // instead of tripping IrmaAvatar's assert.
    final String? initials = hasImage
        ? null
        : credentialName.isNotEmpty
        ? credentialName[0]
        : issuerName.isNotEmpty
        ? issuerName[0]
        : "?";

    Widget avatar = IrmaAvatar(
      size: logoContainerSize,
      logoImage: credentialImageBase64,
      logoPath: credentialImagePath,
      initials: initials,
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
    // Expired credentials are faded the same way.
    final bool faded = disabled || expired;
    if (faded) {
      avatar = Opacity(opacity: 0.4, child: avatar);
    }
    // The badge sits outside the Opacity so it keeps its full colour.
    if (expired) {
      avatar = Stack(
        alignment: Alignment.topRight,
        children: [
          avatar,
          Icon(Icons.error, color: theme.error, size: logoContainerSize * 0.35),
        ],
      );
    }
    final Color titleColor = faded ? theme.neutralDark : theme.dark;
    final Color issuerColor = faded
        ? theme.neutralDark
        : theme.neutralExtraDark;
    final Color trailingColor = faded ? theme.neutral : theme.neutralExtraDark;

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
                    child: Semantics(
                      label: expired
                          ? FlutterI18n.translate(
                              context,
                              "data_tab.expired_label",
                              translationParams: {"name": credentialName},
                            )
                          : null,
                      excludeSemantics: expired,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credentialName,
                            style: theme.themeData.textTheme.headlineMedium!
                                .copyWith(fontSize: 16, color: titleColor),
                          ),
                          Text(
                            expired
                                ? FlutterI18n.translate(
                                    context,
                                    "credential.expired",
                                  )
                                : issuerName,
                            style: theme.themeData.textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 14,
                                  color: expired ? theme.error : issuerColor,
                                ),
                          ),
                        ],
                      ),
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
