import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/session_state.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/flight/flight.dart";
import "../models/disclosure_plan_view.dart";

/// The places of the disclosure screens where a card's picture is drawn,
/// per page and card hash, so one card is seen to travel between them
/// (2.8): it is never drawn at its new place first.
class CardSpots {
  final _keys = <(String, String), GlobalKey>{};

  /// Where the card with [hash] is drawn on [page] ("add", "overview",
  /// "change", "sheet").
  GlobalKey of(String page, String hash) =>
      _keys[(page, hash)] ??= GlobalKey(debugLabel: "spot_${page}_$hash");

  /// Where the card with [hash] is drawn on [page], the first time it is
  /// drawn while building [drawn] (the hashes drawn so far on the page);
  /// null after that: a card drawn twice on a page has one place.
  GlobalKey? firstOf(String page, String hash, Set<String> drawn) =>
      drawn.add(hash) ? of(page, hash) : null;

  /// The boxes of the cards on [page] that are on screen now, by hash.
  Map<String, Rect> boxes(BuildContext context, String page) {
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    if (overlay == null) return const {};
    return {
      for (final MapEntry(:key, :value) in _keys.entries)
        if (key.$1 == page) key.$2: ?_rectOf(value, overlay),
    };
  }

  static Rect? _rectOf(GlobalKey key, RenderBox overlay) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  /// Flies the cards at [from] (boxes by hash, taken before the page
  /// changed) to their places on [page], which are hidden until they land.
  /// Call before the change that builds [page]; the flights start once it
  /// has laid out. A card without a place on [page] does not fly.
  void carry(
    BuildContext context, {
    required Map<String, Rect> from,
    required String page,
    required SelectableCredentialInstance? Function(String hash) card,
    required List<Credential> wallet,
    Duration duration = const Duration(milliseconds: 560),
  }) {
    if (from.isEmpty || MediaQuery.disableAnimationsOf(context)) return;
    final keys = {for (final h in from.keys) h: of(page, h)};
    Flight.hide(keys.values);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var z = 0;
      for (final MapEntry(key: hash, value: rect) in from.entries) {
        final to = keys[hash]!;
        final c = card(hash);
        if (c == null || to.currentContext == null || !context.mounted) {
          Flight.show([to]);
          continue;
        }
        Flight.start(
          context,
          fromRect: rect,
          to: Flight.boxOf(to),
          keys: FlightKey.carry(lift: 0.2, hold: 0.8),
          duration: duration,
          lift: Flight.liftCarried,
          shadow: Flight.shadowCarried,
          radius: const BorderRadius.all(Radius.circular(4)),
          hide: [to],
          z: z++,
          copyKey: Key("spot_flight_$hash"),
          copy: (context, frame) => CredentialCardArt(
            credential: sharedCardFor(c, wallet),
            width: frame.size.width,
          ),
        );
      }
    });
  }
}

/// The candidate of [plan] with [hash], if any.
SelectableCredentialInstance? candidateOf(DisclosurePlan? plan, String hash) {
  for (final choice in plan?.choices ?? const <DisclosureChoice>[]) {
    for (final option in choice.options) {
      for (final slot in option.slots) {
        for (final c in slot.candidates) {
          if (c.hash == hash) return c;
        }
      }
    }
  }
  return null;
}
