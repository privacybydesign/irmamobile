import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../theme/yivi_tone.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/surfaces/status_chip.dart";
import "../models/issuance_view_model.dart";

/// A card that comes into the app: its picture, name and [subtitle], a
/// chip in its head when it matters ([tag]), and every value it holds under
/// it, the [mismatched] ones in red. The question whether to add an offer,
/// the success after it, and the card a requestor gives in return on the
/// share screen.
class ReceivedCardTile extends StatelessWidget {
  final Credential card;
  final String subtitle;
  final OfferTag? tag;

  /// Claim paths ([claimPathKey]) whose value the request cannot use.
  final Set<String> mismatched;

  /// The values are shown as when they are shared: never folded away. The
  /// share screen's card in return has them foldable, and no values row at
  /// all when it holds none.
  final bool disclosure;

  const ReceivedCardTile({
    super.key,
    required this.card,
    required this.subtitle,
    this.tag,
    this.mismatched = const {},
    this.disclosure = true,
  });

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (tag) {
      OfferTag.notCounted => (
        context.tr("share.offer.tag_not_counted"),
        YiviTone.danger,
      ),
      OfferTag.asked => (context.tr("share.spot.asked"), YiviTone.info),
      OfferTag.comesToo => (
        context.tr("share.offer.tag_extra"),
        YiviTone.neutral,
      ),
      null => (null, null),
    };
    return CardTile(
      art: CredentialCardArt(credential: card, width: CardTile.miniWidth),
      title: card.name,
      subtitle: subtitle,
      chip: label == null ? null : StatusChip(label: label, tone: tone!),
      body: [
        if (disclosure || card.attributes.isNotEmpty)
          YiviCredentialCardAttributeList(
            card.attributes,
            credentialId: card.credentialId,
            namespaced: card.isMdoc,
            disclosure: disclosure,
            showDividers: true,
            mismatched: mismatched,
          ),
      ],
    );
  }
}

/// "Valid until {date}" for [card], or null when it does not expire.
String? receivedValidUntil(BuildContext context, Credential card) {
  final expiry = card.expiryDate ?? 0;
  if (expiry <= 0) return null;
  return context.tr("wallet.detail.valid_until", {
    "date": printableDate(
      DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
      context.lang,
    ),
  });
}

/// What comes in the app with [offer]: a tile per card, 12 apart, with how
/// long it is valid (or who gives it) under its name.
List<Widget> receivedCardTiles(
  BuildContext context,
  IssuanceOfferState offer,
) => [
  for (final (i, o) in offer.perCard.indexed)
    Padding(
      padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
      child: ReceivedCardTile(
        key: Key("issuance_card_$i"),
        card: o.card,
        subtitle: receivedValidUntil(context, o.card) ?? o.card.issuer.name,
        tag: o.tag,
        mismatched: o.mismatchedPaths,
      ),
    ),
];
