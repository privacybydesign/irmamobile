import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/schemaless/session_state.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/date_formatter.dart";
import "card_art/credential_card_art.dart";
import "models/credential_card_status.dart";
import "yivi_credential_card_attribute_list.dart";

/// A credential in a disclosure: a thumbnail of its card, its name and
/// issuer, and below that only the attributes that will be shared.
class DisclosedCardTile extends ConsumerWidget {
  final SelectableCredentialInstance instance;

  /// Shown at the top right, e.g. a radio indicator or a remove button.
  final Widget? trailing;

  /// Draws a red ring, for the selected option in a choice.
  final bool selected;

  const DisclosedCardTile({
    super.key,
    required this.instance,
    this.trailing,
    this.selected = false,
  });

  /// The card picture of [instance]: the wallet card with the same hash
  /// (which carries the issuer's design), or one built from the instance.
  static schemaless.Credential cardFor(
    SelectableCredentialInstance instance,
    List<schemaless.Credential> wallet,
  ) =>
      wallet.firstWhereOrNull((c) => c.hash == instance.hash) ??
      schemaless.Credential(
        credentialId: instance.credentialId,
        hash: instance.hash,
        name: instance.name,
        issuer: instance.issuer,
        image: instance.image,
        credentialInstanceIds: {instance.format: instance.hash},
        batchInstanceCountsRemaining: {
          instance.format: instance.batchInstanceCountRemaining,
        },
        attributes: instance.attributes,
        revoked: instance.revoked,
        revocationSupported: instance.revocationSupported,
        issueUrl: instance.issueUrl,
        issuanceDate: instance.issuanceDate,
        expiryDate: instance.expiryDate,
      );

  /// Revoked, expired or expiring soon, as the old card header showed it.
  /// Null while the card is simply valid.
  static Widget? _statusLine(
    BuildContext context,
    YiviPalette palette,
    schemaless.Credential card,
  ) {
    final status = CredentialCardStatus(
      expiryDateUnix: card.expiryDate,
      revoked: card.revoked,
      batchInstanceCountsRemaining: card.batchInstanceCountsRemaining,
      credentialId: card.credentialId,
      issueUrl: card.issueUrl,
    );
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
    final expiry = status.expiryDate?.dateTime;
    final (String? text, Color color) = status.revoked
        ? (
            FlutterI18n.translate(context, "credential.revoked"),
            palette.errorText,
          )
        : status.isExpired && expiry != null
        ? (
            FlutterI18n.translate(
              context,
              "credential.expired_on",
              translationParams: {"date": printableDate(expiry, lang)},
            ),
            palette.errorText,
          )
        : status.hasWarning && expiry != null
        ? (
            FlutterI18n.translate(
              context,
              "credential.expires_on",
              translationParams: {"date": printableDate(expiry, lang)},
            ),
            palette.warningText,
          )
        : (null, palette.text);
    if (text == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        key: const Key("disclosed_card_status"),
        style: palette.body(12, weight: FontWeight.w600).copyWith(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final card = cardFor(instance, wallet);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: BorderSide(
            width: 2,
            color: selected ? palette.primary : Colors.transparent,
          ),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 16,
              children: [
                CredentialCardArt(credential: card, width: 88),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instance.name,
                        style: palette
                            .display(16)
                            .copyWith(color: palette.text),
                      ),
                      Text(
                        instance.issuer.name,
                        style: palette
                            .body(12)
                            .copyWith(color: palette.heading),
                      ),
                      ?_statusLine(context, palette, card),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (instance.attributes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: YiviCredentialCardAttributeList(
                  instance.attributes,
                  credentialId: instance.credentialId,
                  disclosure: true,
                  showDividers: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
