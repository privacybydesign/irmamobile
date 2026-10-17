import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_flight.dart";
import "../../../widgets/credential_card/disclosed_card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
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

  const SharedCardTile({
    super.key,
    required this.bundle,
    this.trailing,
    this.fixLabel,
    this.onFix,
    this.showStatus = true,
    this.landingKey,
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
  static const double miniWidth = 58;

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
        ? _Chip(
            label: FlutterI18n.translate(context, _problemKey(problem)),
            background: palette.errorSurface,
            foreground: palette.errorText,
          )
        : lastUse
        ? _Chip(
            label: FlutterI18n.translate(context, "share.problem.last_use"),
            background: palette.warningSurface,
            foreground: palette.warningText,
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

    return DecoratedBox(
      key: const Key("shared_card_tile"),
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: problem != null
              ? BorderSide(
                  color: palette.errorText.withValues(alpha: 0.35),
                  width: 1.5,
                )
              : BorderSide.none,
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              spacing: 12,
              children: [
                ExcludeSemantics(
                  child: _landing(
                    context,
                    _MiniCards(
                      cards: [
                        for (final c in cards)
                          DisclosedCardTile.cardFor(c, wallet),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette
                            .display(15)
                            .copyWith(color: palette.text),
                      ),
                      Text(
                        issuers,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette
                            .body(12.5)
                            .copyWith(color: palette.secondaryText),
                      ),
                    ],
                  ),
                ),
                ?chip,
                if (trailing case final trailing?)
                  // Kept in place but hidden while the card flies, so the
                  // "Change" pill or radio shows only once it has landed.
                  Visibility(
                    visible: !SharedCardTileInFlight.of(context),
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: trailing,
                  ),
              ],
            ),
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
            if (note != null)
              Container(
                key: const Key("shared_card_note"),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: ShapeDecoration(
                  color: palette.background,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
                child: Text(
                  note,
                  style: palette
                      .body(13)
                      .copyWith(height: 19 / 13, color: palette.heading),
                ),
              ),
            if (onFix != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: const Key("shared_card_fix"),
                  onPressed: onFix,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: palette.body(13, weight: FontWeight.w600),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(fixLabel!),
                ),
              ),
          ],
        ),
      ),
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

/// The cards of a bundle as small card art, overlapping a little when there
/// are several.
class _MiniCards extends StatelessWidget {
  final List<schemaless.Credential> cards;

  const _MiniCards({required this.cards});

  @override
  Widget build(BuildContext context) {
    const w = SharedCardTile.miniWidth;
    const h = w * 226 / 358;
    const step = 20.0;
    return SizedBox(
      width: w + (cards.length - 1) * step,
      height: h + (cards.length - 1) * 6,
      child: Stack(
        children: [
          for (final (i, card) in cards.indexed)
            Positioned(
              left: i * step,
              top: i * 6.0,
              child: CredentialCardArt(credential: card, width: w),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("shared_card_chip"),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: palette
            .body(12, weight: FontWeight.w700)
            .copyWith(color: foreground),
      ),
    );
  }
}
