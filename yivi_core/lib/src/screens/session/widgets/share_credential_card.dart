import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/session_state.dart";
import "../../../theme/theme.dart";
import "../../../widgets/chevron.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/translated_text.dart";

const _footerBandColor = Color(0xFFF5F3F1);
const _valueFontSize = 17.0;

// Municipality credentials all have this one issuer. The municipality that
// holds the data is an attribute of the credential, when it has one.
const _municipalityIssuerId = "pbdf.gemeente";
const _municipalityAttributeId = "municipality";

/// A credential on the share screen: the values first, then a band with the
/// issuer that opens the credential details.
class ShareCredentialCard extends StatelessWidget {
  final SelectableCredentialInstance instance;
  final VoidCallback onShowDetails;
  final Widget? trailing;

  const ShareCredentialCard({
    super.key,
    required this.instance,
    required this.onShowDetails,
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

    return IrmaCard(
      style: status.isExpired || status.revoked
          ? IrmaCardStyle.danger
          : IrmaCardStyle.normal,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
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
          ),
          Material(
            color: _footerBandColor,
            child: InkWell(
              key: const Key("share_card_issuer_band"),
              onTap: onShowDetails,
              child: Padding(
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
                    const Chevron(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
