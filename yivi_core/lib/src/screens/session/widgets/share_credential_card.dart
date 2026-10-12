import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/bold_markers_text.dart";
import "../../../widgets/chevron.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/translated_text.dart";

const _bandColor = Color(0xFFF5F3F1);
const _bandBorderColor = Color(0xFFE3DDD9);
const _valuesShadowColor = Color(0x24000000);
const _cardRadius = Radius.circular(12);

// The band starts this far under the values card, so its corners show behind
// the rounded bottom of the card.
const _bandOverlap = 12.0;
const _bandPadding = 12.0;
const _bandBorderWidth = 1.0;
const _valuesPadding = 14.0;
const _rowPadding = 6.0;
const _bandTextSize = 14.0;
const _bandTextHeight = 20 / 14;
const _chevronSize = 18.0;
const _attributeMetrics = AttributeListMetrics(
  valueFontSize: 17,
  labelLineHeight: 20,
  valueLineHeight: 24,
  rowPadding: _rowPadding,
);

// Municipality credentials all have this one issuer. The municipality that
// holds the data is an attribute of the credential, when it has one. The
// instance only carries the requested attributes, so a request without this
// one shows the issuer name instead.
const _municipalityIssuerId = "pbdf.gemeente";
const _municipalityAttributeId = "municipality";

/// A credential on the share screen: the values on a white card, and below it
/// a band with the issuer. When the request lets the user pick another
/// credential, the band opens that choice and has a chevron; otherwise it is
/// plain text.
class ShareCredentialCard extends StatelessWidget {
  final SelectableCredentialInstance instance;
  final VoidCallback? onChangeChoice;
  final Widget? trailing;

  const ShareCredentialCard({
    super.key,
    required this.instance,
    this.onChangeChoice,
    this.trailing,
  });

  String _issuerName(BuildContext context) {
    final issuer = instance.issuer;
    final municipality = issuer.id == _municipalityIssuerId
        ? instance.attributes
              .firstWhereOrNull(
                (a) => a.claimPath.lastOrNull == _municipalityAttributeId,
              )
              ?.value
              ?.string
        : null;
    if (municipality != null && municipality.isNotEmpty) return municipality;
    if (issuer.name.isNotEmpty) return issuer.name;

    return FlutterI18n.translate(context, "ui.unknown");
  }

  String? _statusKey(CredentialCardStatus status) {
    if (status.revoked) return "credential.revoked";
    if (status.isExpired) return "credential.expired";
    if (status.hasWarning) return "credential.about_to_expire";

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final status = CredentialCardStatus(
      expiryDateUnix: instance.expiryDate,
      revoked: instance.revoked,
      batchInstanceCountsRemaining: {
        instance.format: instance.batchInstanceCountRemaining,
      },
      credentialId: instance.credentialId,
      issueUrl: instance.issueUrl,
    );
    final statusKey = _statusKey(status);
    final danger = status.isExpired || status.revoked;
    final bandBorder = danger ? theme.danger : _bandBorderColor;

    // Listed from the bottom up, so the band is painted first and the shadow
    // of the values card falls on it.
    return Column(
      verticalDirection: VerticalDirection.up,
      crossAxisAlignment: .stretch,
      children: [
        _issuerBand(context, theme, bandBorder),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _bandOverlap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _bandColor,
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: bandBorder,
                      width: _bandBorderWidth,
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              key: const Key("share_card_values"),
              decoration: BoxDecoration(
                color: danger ? theme.surfaceTertiary : theme.light,
                borderRadius: const BorderRadius.all(_cardRadius),
                boxShadow: const [
                  BoxShadow(
                    color: _valuesShadowColor,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: _values(context, theme, status, statusKey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _values(
    BuildContext context,
    IrmaThemeData theme,
    CredentialCardStatus status,
    String? statusKey,
  ) {
    return Padding(
      padding: .symmetric(
        horizontal: theme.defaultSpacing,
        vertical: _valuesPadding - _rowPadding,
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                if (statusKey != null) ...[
                  TranslatedText(
                    statusKey,
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: status.hasWarning && !status.isExpired
                          ? theme.warning
                          : theme.error,
                    ),
                  ),
                  SizedBox(height: theme.smallSpacing),
                ],
                YiviCredentialCardAttributeList(
                  instance.attributes,
                  metrics: _attributeMetrics,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _issuerBand(
    BuildContext context,
    IrmaThemeData theme,
    Color borderColor,
  ) {
    final text = Padding(
      padding: .fromLTRB(
        theme.defaultSpacing + _bandBorderWidth,
        _bandPadding,
        _bandPadding + _bandBorderWidth,
        _bandPadding + _bandBorderWidth,
      ),
      child: Row(
        spacing: theme.smallSpacing,
        children: [
          Expanded(
            child: BoldMarkersText(
              "disclosure_permission.share_v2.certified_by",
              translationParams: {"issuerName": _issuerName(context)},
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: _bandTextSize,
                height: _bandTextHeight,
                color: theme.neutralExtraDark,
              ),
            ),
          ),
          if (onChangeChoice != null)
            Chevron(size: _chevronSize, color: theme.neutralExtraDark),
        ],
      ),
    );
    const bandRadius = BorderRadius.vertical(bottom: _cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bandColor,
        borderRadius: bandRadius,
        border: Border(
          left: BorderSide(color: borderColor, width: _bandBorderWidth),
          right: BorderSide(color: borderColor, width: _bandBorderWidth),
          bottom: BorderSide(color: borderColor, width: _bandBorderWidth),
        ),
      ),
      child: onChangeChoice == null
          ? KeyedSubtree(key: const Key("share_card_issuer_band"), child: text)
          : Semantics(
              button: true,
              hint: FlutterI18n.translate(
                context,
                "disclosure_permission.change_choice",
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const Key("share_card_issuer_band"),
                  borderRadius: bandRadius,
                  onTap: onChangeChoice,
                  child: text,
                ),
              ),
            ),
    );
  }
}
