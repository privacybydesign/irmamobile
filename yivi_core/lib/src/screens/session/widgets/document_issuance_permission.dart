import "dart:math" as math;

import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_palette.dart";
import "../../../util/date_formatter.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/models/credential_card_layout.dart";
import "../../../widgets/credential_card/models/credential_card_status.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/translated_text.dart";

/// The permission screen for a document read from its chip, as on the
/// design's permission board: the
/// question, the document's card, its data in a group with the ages folded
/// into one row, and how long it is valid and how often it can be shared.
class DocumentIssuancePermission extends StatelessWidget {
  const DocumentIssuancePermission({
    required this.issuedCredentials,
    this.onDismiss,
    this.onGivePermission,
    this.returnedFromIssuer,
    super.key,
  });

  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  /// Name of the issuer whose website the user just came back from, if any.
  final String? returnedFromIssuer;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        titleTranslationKey: "issuance.title",
        leading: null,
        hasBorder: false,
        actions: [if (onDismiss != null) IrmaCloseButton(onTap: onDismiss!)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.min(
                CredentialCardArt.designWidth,
                constraints.maxWidth,
              );
              return Column(
                crossAxisAlignment: .stretch,
                children: [
                  if (returnedFromIssuer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: TranslatedText(
                        "external_issuer.returned",
                        translationParams: {"issuer": returnedFromIssuer!},
                        style: palette.display(18),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: TranslatedText(
                      "issuance.description",
                      isHeader: true,
                      style: palette
                          .display(22)
                          .copyWith(height: 30 / 22, color: palette.heading),
                    ),
                  ),
                  for (final credential in issuedCredentials) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: CredentialCardArt(
                        credential: credential,
                        width: cardWidth,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DocumentData(credential: credential),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: DocumentFlowFooter(
        buttons: onGivePermission != null
            ? [
                DocumentFlowButton(
                  key: DocumentFlowButton.primaryKey,
                  labelKey: "issuance.add",
                  onPressed: onGivePermission,
                ),
                DocumentFlowButton(
                  key: DocumentFlowButton.secondaryKey,
                  labelKey: "document_flow.cancel",
                  onPressed: onDismiss,
                  style: .outline,
                ),
              ]
            : [
                DocumentFlowButton(
                  key: DocumentFlowButton.primaryKey,
                  labelKey: "session.navigation_bar.back",
                  onPressed: onDismiss,
                ),
              ],
      ),
    );
  }
}

/// The data of the document in one group: a row per attribute, the ages
/// folded into one row, and the validity in two cells at the bottom.
class _DocumentData extends StatelessWidget {
  final schemaless.Credential credential;

  const _DocumentData({required this.credential});

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

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (credential.attributes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: YiviCredentialCardAttributeList(
                credential.attributes,
                credentialId: credential.credentialId,
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
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";

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

    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    final expiry = status.expiryDate?.dateTime;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            child: cell(
              t("credential.valid_until"),
              expiry == null
                  ? t("credential.indefinite_validity")
                  : printableDate(expiry, lang),
              tone(status.timeExpireState),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: palette.divider),
          Expanded(
            child: cell(
              t("credential.sharable"),
              status.instanceCount == null
                  ? t("credential.sharable_unlimited")
                  : t("credential.sharable_count", {
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
