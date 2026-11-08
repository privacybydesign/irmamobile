import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/models/credential_card_layout.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/surface_card.dart";

/// The data of a document read from its chip, for the question whether
/// to add it ([IssuancePermission]), in one group: a row per attribute, the ages
/// folded into one row, and the validity in two cells at the bottom.
class DocumentIssuanceData extends StatelessWidget {
  final schemaless.Credential credential;

  const DocumentIssuanceData({super.key, required this.credential});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final status = CredentialCardStatus(
      expiryDateUnix: credential.expiryDate,
      revoked: credential.revoked,
      batchInstanceCountsRemaining: credential.batchInstanceCountsRemaining,
      lowInstanceCountThreshold: 0,
      credentialId: credential.credentialId,
      issueUrl: credential.issueUrl,
    );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (credential.attributes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: YiviCredentialCardAttributeList(
                credential.attributes,
                credentialId: credential.credentialId,
                namespaced: credential.isMdoc,
                ageDisplay: AgeDisplay.collapsed,
                layout: CredentialCardLayout.document,
                showDividers: true,
              ),
            ),
          if (!status.revoked) ...[
            Divider(height: 1, thickness: 1, color: palette.divider),
            _Validity(status: status),
          ],
        ],
      ),
    );
  }
}

/// "Valid until" and "Sharable" side by side, split by a thin line.
class _Validity extends StatelessWidget {
  final CredentialCardStatus status;

  const _Validity({required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final lang = context.lang;

    Color tone(ExpireState state) => switch (state) {
      ExpireState.notExpired => palette.text,
      ExpireState.almostExpired => palette.warningText,
      ExpireState.expired => palette.danger,
    };

    Widget cell(String label, String value, Color color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            label,
            style: palette
                .body(13)
                .copyWith(height: 18 / 13, color: palette.secondaryText),
          ),
          Text(
            value,
            style: palette
                .body(15, weight: FontWeight.w700)
                .copyWith(height: 22 / 15, color: color),
          ),
        ],
      ),
    );

    final expiry = status.expiryDate?.dateTime;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            child: cell(
              context.tr("credential.valid_until"),
              expiry == null
                  ? context.tr("credential.indefinite_validity")
                  : printableDate(expiry, lang),
              tone(status.timeExpireState),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: palette.divider),
          Expanded(
            child: cell(
              context.tr("credential.sharable"),
              status.instanceCount == null
                  ? context.tr("credential.sharable_unlimited")
                  : context.tr("credential.sharable_count", {
                      "count": "${status.instanceCount}",
                    }),
              tone(status.instanceExpireState),
            ),
          ),
        ],
      ),
    );
  }
}
