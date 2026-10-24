import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_flight.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../models/disclosure_view_model.dart";

/// Marks a [SharedCardTile] as flying in a hero (or following a drag), so
/// its trailing control is hidden until it lands.
class SharedCardTileInFlight extends InheritedWidget {
  const SharedCardTileInFlight({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SharedCardTileInFlight>() !=
      null;

  @override
  bool updateShouldNotify(SharedCardTileInFlight oldWidget) => false;
}

/// One requested item on the share screen: the selected card (or set of
/// cards that go together) as small card art, its name and issuer, and only
/// the values that are shared.
///
/// [trailing] sits at the end of the header: a "Change" pill, a remove
/// button for optional data, or nothing. A card with a [CardProblem] gets a
/// red outline, its chip and a one-line reason, plus [onFix] ("Add a new
/// address") when it can be renewed from Yivi.
class SharedCardTile extends ConsumerWidget {
  final DisclosureBundle bundle;
  final Widget? trailing;
  final String? fixLabel;
  final VoidCallback? onFix;

  /// Shows the problem or last-use chip and note. Off after sharing, when
  /// they no longer apply.
  final bool showStatus;

  /// Marks the small card art as where a card added in the Change sheet
  /// lands (a [CardFlightLanding]).
  final GlobalKey? landingKey;

  /// A strip across the bottom: another choice, or that the cards go
  /// together. Not shown on a card with a problem in [problemStrip] mode.
  final Widget? footer;

  /// The share screen's way to show a problem: the note in a red strip
  /// across the bottom, with [fixLabel] as a pill in it. Otherwise (the
  /// Change sheet) the note and the fix are in the body.
  final bool problemStrip;

  /// The card was added during this request: a green "New" chip.
  final bool isNew;

  /// Optional data that is not included: the card at half strength inside a
  /// dashed edge, with [dashGap] left open for a pill on that edge.
  final bool ghost;
  final ({double width, double fromEnd})? dashGap;

  const SharedCardTile({
    super.key,
    required this.bundle,
    this.trailing,
    this.fixLabel,
    this.onFix,
    this.showStatus = true,
    this.landingKey,
    this.footer,
    this.problemStrip = false,
    this.isNew = false,
    this.ghost = false,
    this.dashGap,
  }) : assert((fixLabel == null) == (onFix == null));

  /// The art, marked as a landing spot. Not the copy in a hero flight: the
  /// flight builds the tile a second time, and a key can be in the tree once.
  Widget _landing(BuildContext context, Widget art) {
    final key = landingKey;
    return key == null || SharedCardTileInFlight.of(context)
        ? art
        : CardFlightLanding(landingKey: key, child: art);
  }

  /// Width of the small card art, at the card's 358:226 ratio.
  static const double miniWidth = CardTile.miniWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final wallet =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final cards = bundle.credentials;
    final problem = showStatus ? problemOfBundle(bundle) : null;
    final lastUse = showStatus && problem == null && cards.any(isLastUse);
    final name = cards.map((c) => c.name).join(" + ");
    final issuers = cards.map((c) => c.issuer.name).toSet().join(", ");

    final chip = problem != null
        ? CardTileChip(
            key: const Key("shared_card_chip"),
            label: FlutterI18n.translate(context, _problemKey(problem)),
            background: palette.errorSurface,
            foreground: palette.errorText,
          )
        : lastUse
        ? CardTileChip(
            key: const Key("shared_card_chip"),
            label: FlutterI18n.translate(context, "share.problem.last_use"),
            background: palette.warningSurface,
            foreground: palette.warningText,
          )
        : isNew
        ? CardTileChip(
            key: const Key("shared_card_new"),
            label: FlutterI18n.translate(context, "share.new_chip"),
            background: palette.successSurface,
            foreground: palette.successText,
          )
        : null;

    final note = problem != null
        ? FlutterI18n.translate(
            context,
            "share.problem.${_problemName(problem)}_note",
            translationParams: {"issuer": cards.first.issuer.name},
          )
        : lastUse
        ? FlutterI18n.translate(context, "share.problem.last_use_note")
        : null;

    // On the share screen a problem is a red strip with its fix in it.
    final strip = problemStrip && problem != null;
    final Widget? bottom = strip
        ? CardTileStrip(
            key: const Key("shared_card_problem"),
            background: palette.errorSurface,
            line: palette.errorText.withValues(alpha: 0.2),
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: palette.errorText,
                ),
              ),
              Expanded(
                child: Text(
                  note!,
                  key: const Key("shared_card_note"),
                  style: palette
                      .body(13.5, weight: FontWeight.w600)
                      .copyWith(height: 19 / 13.5, color: palette.errorText),
                ),
              ),
              if (onFix != null)
                SmallPill(
                  key: const Key("shared_card_fix"),
                  label: fixLabel!,
                  tone: SmallPillTone.onDanger,
                  onPressed: onFix,
                ),
            ],
          )
        : footer;

    return CardTile(
      key: const Key("shared_card_tile"),
      footer: bottom,
      dashed: ghost,
      faded: ghost,
      dashGap: dashGap,
      outline: problem != null
          ? palette.errorText.withValues(alpha: 0.35)
          : null,
      art: _landing(
        context,
        CardTileMiniCards(cards: [for (final c in cards) _cardFor(c, wallet)]),
      ),
      title: name,
      subtitle: issuers,
      chip: chip,
      trailing: trailing == null
          ? null
          // Kept in place but hidden while the card flies, so the "Change"
          // pill or radio shows only once it has landed.
          : Visibility(
              visible: !SharedCardTileInFlight.of(context),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: trailing!,
            ),
      body: [
        for (final c in cards)
          if (c.attributes.isNotEmpty)
            Opacity(
              opacity: problem != null ? 0.55 : 1,
              child: YiviCredentialCardAttributeList(
                c.attributes,
                credentialId: c.credentialId,
                disclosure: true,
                showDividers: true,
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
              color: palette.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(YiviCorners.card),
                ),
              ),
            ),
            child: Text(
              note,
              style: palette
                  .body(13)
                  .copyWith(height: 19 / 13, color: palette.heading),
            ),
          ),
        if (onFix != null && !strip)
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
    CardProblem.usedUp => "used_up",
    CardProblem.expired => "expired",
  };

  static String _problemKey(CardProblem p) =>
      "share.problem.${_problemName(p)}";
}

/// The card picture of [instance]: the wallet card with the same hash
/// (which carries the issuer's design), or one built from the instance.
schemaless.Credential _cardFor(
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
