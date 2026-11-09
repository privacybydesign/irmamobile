import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/count_badge.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/credential_card/faded_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/press_scale.dart";
import "shared_card_tile.dart";

/// A row of an [EmptyCardSpot]: a field, its value, and whether that value
/// is what the request asks of the card ("Asked").
typedef SpotRow = (String label, String value, bool asked);

/// The rows of an [EmptyCardSpot] for [card]: each field the request asks a
/// set value for, with that value, marked "Asked". Fields asked without a
/// value are not listed: the card is not there yet, so there is nothing to
/// show.
List<SpotRow> emptySpotRows(BuildContext context, CredentialDescriptor card) {
  return [
    for (final a in card.attributes)
      if (a.requestedValue case final v? when v.hasConcreteValue)
        (
          a.effectiveDisplayName,
          localizedAttributeText(context, v) ?? "",
          true,
        ),
  ];
}

/// A card that is not in the app yet: a dashed [CardTile] with the card's
/// own picture faded under a "+" (or the types to choose from, [kinds]),
/// its name, the values the request asks of it ("Asked"), and a strip at its
/// foot that says it is "Not in your app yet". The whole card is the button
/// that adds it: it has no pill.
///
/// The one widget for this: on the share screen for a required card, and in
/// the Change sheet for each type that can be added.
class EmptyCardSpot extends StatelessWidget {
  final GlobalKey? landingKey;
  final String title;
  final String subtitle;

  /// The values the request asks of the card (see [emptySpotRows]).
  final List<SpotRow> rows;

  /// "{field} must be {value}" for each value the request needs, when there
  /// are no [rows] to show them in.
  final List<String> requirements;

  /// Null when it cannot be added from Yivi.
  final VoidCallback? onTap;

  /// The types to choose from when there is more than one, shown as their
  /// own small cards in place of the dashed one (two side by side, or three
  /// and "+n"), and the title on up to three lines. The Change sheet passes
  /// them only for a set of cards that go together ([together]); otherwise
  /// it shows one spot per type.
  final List<CredentialDescriptor>? kinds;

  /// Cards only accepted together: the subtitle (what to do) on up to three
  /// lines, and [kinds] are the set, not a choice.
  final bool together;

  /// The card type, for its faded picture; null draws a dashed box.
  final CredentialDescriptor? descriptor;

  /// What the strip at its foot says; "Not in your app yet" by default
  /// ("You don't share this" for optional data).
  final String? strip;

  const EmptyCardSpot({
    super.key,
    this.landingKey,
    required this.title,
    required this.subtitle,
    this.rows = const [],
    this.requirements = const [],
    this.onTap,
    this.kinds,
    this.together = false,
    this.descriptor,
    this.strip,
  });

  /// The picture, where an added card lands (hidden while it flies in).
  Widget _landing(Widget art) {
    final key = landingKey;
    return key == null ? art : FlightSpot(flightKey: key, child: art);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final canAdd = onTap != null;
    final choice = kinds != null && kinds!.length > 1 ? kinds : null;
    final tile = CardTile(
      dashed: true,
      titleMaxLines: choice == null ? 1 : 3,
      subtitleMaxLines: together ? 3 : 1,
      art: _landing(
        choice != null
            ? _KindsArt(kinds: choice)
            : FadedCardArt(descriptor: descriptor, canAdd: canAdd),
      ),
      title: title,
      subtitle: subtitle,
      footer: CardTileStrip(
        line: palette.link.withValues(alpha: 0.12),
        children: [
          Expanded(
            child: Text(
              strip ?? FlutterI18n.translate(context, "share.not_in_app_yet"),
              style: CardTileStrip.textStyle(context),
            ),
          ),
        ],
      ),
      body: [
        if (rows.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (n, (label, value, asked)) in rows.indexed)
                Container(
                  decoration: BoxDecoration(
                    border: n == 0
                        ? null
                        : Border(top: BorderSide(color: palette.divider)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: attributeLabelStyle(context)),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            value,
                            style: attributeValueStyle(context, palette.text),
                          ),
                          if (asked)
                            ValueTag(
                              key: const Key("value_tag_asked"),
                              text: FlutterI18n.translate(
                                context,
                                "share.spot.asked",
                              ),
                              tone: ValueTagTone.asked,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        for (final r in requirements)
          Text(
            r,
            style: palette.body(12.5).copyWith(color: palette.secondaryText),
          ),
      ],
    );
    return Semantics(
      button: canAdd,
      child: GestureDetector(
        key: const Key("empty_spot_add"),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(scale: PressScale.card, enabled: canAdd, child: tile),
      ),
    );
  }
}

/// The types an empty spot can be filled with, as their own cards, faded:
/// two overlapping, or the first three stacked with "+n" for the rest.
class _KindsArt extends StatelessWidget {
  final List<CredentialDescriptor> kinds;

  const _KindsArt({required this.kinds});

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final two = kinds.length == 2;
    final shown = kinds.take(two ? 2 : 3).toList();
    final more = kinds.length - shown.length;
    final width = two ? 46.0 : 42.0;
    Widget card(int i, CredentialDescriptor d) {
      final (x, y, alpha) = two
          ? (i * 12.0, i * 14.0, i == 0 ? 0.45 : 0.7)
          : (i * 7.0, i * 7.0, 0.4 + 0.25 * i);
      return Positioned(
        left: x,
        top: y,
        // A thin ring in the card's colour keeps the cards apart.
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius:
                  CredentialCardArt.radiusFor(width) +
                  const BorderRadius.all(Radius.circular(1.5)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Opacity(
              opacity: alpha,
              child: CredentialTypeThumbnail(descriptor: d, width: width),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: SharedCardTile.miniWidth,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, d) in shown.indexed) card(i, d),
          if (more > 0)
            Positioned(
              right: -4,
              bottom: -2,
              child: CountBadge(
                key: const Key("empty_spot_more"),
                count: more,
                fill: palette.link,
                ink: Colors.white,
                size: 20,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
