import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/chevron.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/translated_text.dart";

const _footerBandColor = Color(0xFFF5F3F1);
const _valueFontSize = 17.0;

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

    // The band is the base of the card. The values sit on a white card with
    // rounded corners on top of it, whose shadow falls on the band.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: theme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: _footerBandColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: theme.borderRadius,
          side: danger ? BorderSide(color: theme.danger) : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            DecoratedBox(
              key: const Key("share_card_values"),
              decoration: BoxDecoration(
                color: danger ? theme.surfaceTertiary : theme.light,
                borderRadius: theme.borderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: _values(context, theme, status, statusKey),
            ),
            _issuerBand(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _values(
    BuildContext context,
    IrmaThemeData theme,
    CredentialCardStatus status,
    String? statusKey,
  ) {
    return Padding(
      padding: .all(theme.defaultSpacing),
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
                  valueFontSize: _valueFontSize,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _issuerBand(BuildContext context, IrmaThemeData theme) {
    final text = Padding(
      padding: .symmetric(
        horizontal: theme.defaultSpacing,
        vertical: theme.smallSpacing,
      ),
      child: Row(
        children: [
          Expanded(
            child: TranslatedText(
              "disclosure_permission.share_v2.certified_by",
              translationParams: {"issuerName": _issuerName(context)},
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onChangeChoice != null) const Chevron(),
        ],
      ),
    );

    if (onChangeChoice == null) {
      return KeyedSubtree(
        key: const Key("share_card_issuer_band"),
        child: text,
      );
    }
    return Semantics(
      button: true,
      hint: FlutterI18n.translate(
        context,
        "disclosure_permission.change_choice",
      ),
      child: InkWell(
        key: const Key("share_card_issuer_band"),
        onTap: onChangeChoice,
        child: text,
      ),
    );
  }
}
