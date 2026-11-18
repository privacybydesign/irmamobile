import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/log_entry.dart";
import "../../../models/session_state.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_tone.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/surfaces/status_chip.dart";
import "../models/disclosure_view_model.dart";

/// One requested item on the share screen: the selected card (or set of
/// cards that go together) as small card art, its name and issuer, and only
/// the values that are shared.
///
/// A card with a [CardProblem] gets its chip, its values greyed, and a calm
/// strip across the bottom that says it can't be used any more, with the way
/// on ([problemAction]) at its end: on the share screen and in the Change
/// sheet alike, where "Wijzig keuze" is on a card without a problem.
class SharedCardTile extends ConsumerWidget {
  final DisclosureBundle bundle;

  /// Marks the small card art as where a card added in the Change sheet
  /// lands (a [FlightSpot]).
  final GlobalKey? landingKey;

  /// A strip across the bottom: another choice, or that the cards go
  /// together. A card with a problem has its problem strip instead.
  final Widget? footer;

  /// The card was added during this request: a green "New" chip.
  final bool isNew;

  /// A button at the end of the problem strip: get the card again, or change
  /// the choice.
  final Widget? problemAction;

  const SharedCardTile({
    super.key,
    required this.bundle,
    this.landingKey,
    this.footer,
    this.isNew = false,
    this.problemAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet = ref.watch(walletCardsProvider);
    final cards = bundle.credentials;
    final problem = problemOfBundle(bundle);
    final name = cards.map((c) => c.name).join(" + ");
    final issuers = cards.map((c) => c.issuer.name).toSet().join(", ");

    final chip = problem != null
        ? StatusChip(
            key: const Key("shared_card_chip"),
            label: context.tr(_problemKey(problem)),
            tone: YiviTone.danger,
          )
        : isNew
        ? StatusChip(
            key: const Key("shared_card_new"),
            label: context.tr("share.new_chip"),
            tone: YiviTone.success,
          )
        : null;

    final note = problem != null
        ? context.tr("share.problem.${_problemName(problem)}_note", {
            "issuer": cards.first.issuer.name,
          })
        : null;

    // A problem is a calm strip that says what is wrong.
    final Widget? bottom = problem != null
        ? CardTileStrip(
            key: const Key("shared_card_problem"),
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: palette.secondaryText,
                ),
              ),
              Expanded(
                child: Text(
                  note!,
                  key: const Key("shared_card_note"),
                  style: CardTileStrip.textStyle(context),
                ),
              ),
              ?problemAction,
            ],
          )
        : footer;
    final single = cards.length == 1 ? cards.single.name : null;

    return CardTile(
      key: const Key("shared_card_tile"),
      footer: bottom,
      // Marked as a landing spot.
      art: FlightSpot.maybe(
        landingKey,
        CardTileMiniCards(
          cards: [for (final c in cards) sharedCardFor(c, wallet)],
        ),
      ),
      title: name,
      subtitle: issuers,
      chip: chip,
      body: [
        for (final c in cards)
          if (c.attributes.isNotEmpty)
            Opacity(
              opacity: problem != null ? 0.55 : 1,
              child: YiviCredentialCardAttributeList(
                c.attributes,
                credentialId: c.credentialId,
                namespaced: c.format == CredentialFormat.msoMdoc,
                disclosure: true,
                showDividers: true,
                matchedTag: context.tr("share.match_tag"),
                hideLabel: single,
                // What the requestor asked for exactly, in green.
                matched: {
                  for (final a in c.attributes)
                    if (a.requestedValue case final wanted?
                        when wanted.hasConcreteValue &&
                            sameValue(a.value, wanted))
                      claimPathKey(a.claimPath),
                },
              ),
            ),
      ],
    );
  }

  static String _problemName(CardProblem p) => switch (p) {
    CardProblem.revoked => "revoked",
    CardProblem.expired => "expired",
  };

  static String _problemKey(CardProblem p) =>
      "share.problem.${_problemName(p)}";
}

/// A [CardTileOutline] in [color] that fades in over [duration] when it
/// appears, and then stays: the chosen card in the Change sheet, a card
/// that landed on the share screen. [outlineKey] is the outline's key.
class FadingTileOutline extends StatelessWidget {
  final bool shown;
  final Color color;
  final Duration duration;
  final Key? outlineKey;
  final Widget child;

  const FadingTileOutline({
    super.key,
    required this.shown,
    required this.color,
    required this.duration,
    this.outlineKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!shown) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: YiviMotion.duration(context, duration),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => CardTileOutline(
        key: outlineKey,
        shown: true,
        color: color.withValues(alpha: t),
        child: child!,
      ),
    );
  }
}

/// The card picture of [instance]: the wallet card with the same hash
/// (which carries the issuer's design), or one built from the instance.
Credential sharedCardFor(
  SelectableCredentialInstance instance,
  List<Credential> wallet,
) =>
    wallet.firstWhereOrNull((c) => c.hash == instance.hash) ??
    Credential(
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
      isSingleton: instance.isSingleton,
    );
