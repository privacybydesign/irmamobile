import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/theme.dart";
import "../chevron.dart";
import "../data_tab_icon.dart";
import "../irma_avatar.dart";
import "../irma_card.dart";
import "models/credential_card_status.dart";

enum CredentialCardLayout {
  standard,

  /// The card of the redesigned data tab and add data screen: 72 px high with
  /// a 44 px logo, a chevron for opening and a plus for adding.
  compact,
}

const _logoSize = 52.0;
const _compactLogoSize = 44.0;
const _compactMinHeight = 72.0;
const _compactChevronSize = 20.0;
const _compactPlusSize = 26.0;
const _badgeSize = 20.0;
const _badgeBorderWidth = 2.0;
const _badgeOverhang = 4.0;
const _fadedLogoOpacity = 0.4;
const _expiredLogoOpacity = 0.45;
const _expiredSurface = Color(0xFFF7F5F4);

class SchemalessYiviCredentialTypeCard extends StatelessWidget {
  final String? credentialImagePath;
  final Widget? credentialImageBase64;
  final String credentialName;
  final String credentialId;
  final String issuerName;

  final VoidCallback? onTap;
  final bool checked;

  /// Shown in place of the chevron. The compact layout draws the board's plus
  /// for any value.
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

  final CredentialCardLayout layout;

  const SchemalessYiviCredentialTypeCard({
    this.onTap,
    this.checked = false,
    this.trailingIcon,
    this.disabled = false,
    this.disabledHint,
    this.expireState = ExpireState.notExpired,
    this.layout = CredentialCardLayout.standard,
    this.credentialImagePath,
    this.credentialImageBase64,
    required this.credentialName,
    required this.credentialId,
    required this.issuerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final bool compact = layout == CredentialCardLayout.compact;
    final double logoContainerSize = compact ? _compactLogoSize : _logoSize;
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
    // 4.5:1 contrast minimum on a still-interactive control). Expired
    // credentials are faded the same way.
    final bool faded = disabled || expired;
    if (faded) {
      avatar = Opacity(
        opacity: expired ? _expiredLogoOpacity : _fadedLogoOpacity,
        child: avatar,
      );
    }
    // The badge sits outside the Opacity so it keeps its full colour.
    if (expired) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            top: -_badgeOverhang,
            right: -_badgeOverhang,
            child: _ExpiredBadge(),
          ),
        ],
      );
    }
    final Color titleColor = faded ? theme.neutralDark : theme.dark;
    final Color issuerColor = faded
        ? theme.neutralDark
        : theme.neutralExtraDark;
    final Color trailingColor = faded ? theme.neutral : theme.neutralExtraDark;
    final Color? surface = expired ? _expiredSurface : null;

    return Semantics(
      enabled: !disabled,
      hint: disabled ? disabledHint : null,
      child: IrmaCard(
        margin: EdgeInsets.zero,
        color: surface,
        child: Material(
          color: surface,
          child: InkWell(
            key: Key("${credentialId}_tile"),
            onTap: onTap,
            // Greyed-out credentials stay tappable so onTap can explain why they
            // are unavailable.
            child: Container(
              constraints: BoxConstraints(
                minHeight: compact ? _compactMinHeight : 0,
              ),
              // Tighter right padding when showing the default chevron so it
              // sits closer to the card edge. Action icons (e.g. the `+` on the
              // add-data screen) keep the standard padding.
              padding: compact
                  ? EdgeInsets.symmetric(
                      horizontal: theme.defaultSpacing,
                      vertical: theme.tinySpacing,
                    )
                  : trailingIcon == null
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
                  SizedBox(
                    width: compact
                        ? theme.defaultSpacing
                        : theme.defaultSpacing - theme.tinySpacing,
                  ),
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
                                .copyWith(
                                  fontSize: 16,
                                  height: compact ? 22 / 16 : null,
                                  color: titleColor,
                                ),
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
                                  height: compact ? 20 / 14 : null,
                                  fontWeight: expired ? FontWeight.w600 : null,
                                  color: expired ? theme.error : issuerColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: compact ? theme.defaultSpacing : theme.smallSpacing,
                  ),
                  if (compact && trailingIcon != null)
                    DataTabIcon(
                      DataTabGlyph.plusCircle,
                      size: _compactPlusSize,
                      color: trailingColor,
                    )
                  else if (compact)
                    DataTabIcon(
                      DataTabGlyph.chevronRight,
                      size: _compactChevronSize,
                      color: expired
                          ? theme.neutralDark
                          : theme.neutralExtraDark,
                    )
                  else if (trailingIcon != null)
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

class _ExpiredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      width: _badgeSize,
      height: _badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.error,
        border: Border.all(color: theme.light, width: _badgeBorderWidth),
      ),
      child: Text(
        "!",
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
          color: theme.light,
        ),
      ),
    );
  }
}
