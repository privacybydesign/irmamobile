import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/status_chip.dart";
import "../models/disclosure_view_model.dart";

/// One requested item on the share screen: the selected card (or set of
/// cards that go together) as small card art, its name and issuer, and only
/// the values that are shared.
///
/// A card with a [CardProblem] gets
/// its chip, its values greyed, and a calm line that says it can't be used
/// any more; the fix is the share button's, not the card's. In the Change
/// sheet [onFix] ("Add a new passport") sits under that line.
class SharedCardTile extends ConsumerWidget {
  final DisclosureBundle bundle;
  final String? fixLabel;
  final VoidCallback? onFix;

  /// Marks the small card art as where a card added in the Change sheet
  /// lands (a [FlightSpot]).
  final GlobalKey? landingKey;

  /// A strip across the bottom: another choice, or that the cards go
  /// together. Not shown on a card with a problem in [problemStrip] mode.
  final Widget? footer;

  /// The share screen's way to show a problem: the note in a strip across
  /// the bottom, in place of [footer]. Otherwise (the Change sheet) the note
  /// and the fix are in the body.
  final bool problemStrip;

  /// The card was added during this request: a green "New" chip.
  final bool isNew;

  /// A button at the end of the problem strip ([problemStrip]): get the card
  /// again, or change the choice.
  final Widget? problemAction;

  const SharedCardTile({
    super.key,
    required this.bundle,
    this.fixLabel,
    this.onFix,
    this.landingKey,
    this.footer,
    this.problemStrip = false,
    this.isNew = false,
    this.problemAction,
  }) : assert((fixLabel == null) == (onFix == null));

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
            label: FlutterI18n.translate(context, _problemKey(problem)),
            tone: DialogTone.danger,
          )
        : isNew
        ? StatusChip(
            key: const Key("shared_card_new"),
            label: FlutterI18n.translate(context, "share.new_chip"),
            tone: DialogTone.success,
          )
        : null;

    final note = problem != null
        ? FlutterI18n.translate(
            context,
            "share.problem.${_problemName(problem)}_note",
            translationParams: {"issuer": cards.first.issuer.name},
          )
        : null;

    // On the share screen a problem is a calm strip that says what is
    // wrong; the share button does the fix.
    final strip = problemStrip && problem != null;
    final Widget? bottom = strip
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
                matchedTag: FlutterI18n.translate(context, "share.match_tag"),
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
        if (note != null && !strip)
          Container(
            key: const Key("shared_card_note"),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: ShapeDecoration(
              // One step lighter than the card (the page colour in light).
              color: palette.tint,
              shape: const RoundedRectangleBorder(
                borderRadius: YiviCorners.cardRadius,
              ),
            ),
            child: Text(
              note,
              style: palette
                  .body(13)
                  .copyWith(height: 19 / 13, color: palette.heading),
            ),
          ),
        if (onFix != null && !problemStrip)
          Align(
            alignment: Alignment.centerLeft,
            child: SmallPill(
              key: const Key("shared_card_fix"),
              label: fixLabel!,
              tone: SmallPillTone.primary,
              onPressed: onFix,
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
schemaless.Credential sharedCardFor(
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
      isSingleton: instance.isSingleton,
    );
