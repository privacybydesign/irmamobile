import "package:flutter/rendering.dart" show RenderFractionalTranslation;
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/session_state.dart";
import "../../../util/laid_out_box.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/sheet/sheet.dart";
import "../models/disclosure_plan_view.dart";

/// The places of the disclosure screens where a card's picture is drawn,
/// per page and card hash, so one card is seen to travel between them
/// (2.8): it is never drawn at its new place first.
class CardSpots {
  final _keys = <(String, String), GlobalKey>{};

  /// How the cards lay when [boxes] last measured them (a fanned pile), by
  /// page and hash: where a flight from there starts turned.
  final _turns = <(String, String), double>{};

  /// Where the card with [hash] is drawn on [page] ("add", "overview",
  /// "change", "sheet").
  GlobalKey of(String page, String hash) =>
      _keys[(page, hash)] ??= GlobalKey(debugLabel: "spot_${page}_$hash");

  /// Where the card with [hash] is drawn on [page], the first time it is
  /// drawn while building [drawn] (the hashes drawn so far on the page);
  /// null after that: a card drawn twice on a page has one place.
  GlobalKey? firstOf(String page, String hash, Set<String> drawn) =>
      drawn.add(hash) ? of(page, hash) : null;

  /// The boxes of the cards on [page] that are on screen now, by hash: as
  /// they would lie unturned, around the same middle (see [_placeOf]).
  Map<String, Rect> boxes(BuildContext context, String page) {
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    if (overlay == null) return const {};
    final result = <String, Rect>{};
    for (final MapEntry(:key, :value) in _keys.entries) {
      if (key.$1 != page) continue;
      final place = _placeOf(value, overlay);
      if (place == null) continue;
      result[key.$2] = place.rect;
      _turns[key] = place.turn;
    }
    return result;
  }

  /// Where the card at [key] is in [overlay], unturned, and its turn: a
  /// flight to that box with that turn ends exactly on the card.
  static ({Rect rect, double turn})? _placeOf(
    GlobalKey key,
    RenderBox overlay,
  ) => key.currentContext.placeIn(overlay);

  /// [_placeOf] as it will be once the pages around it stop moving: without
  /// the slides between it and [overlay] (a page sliding in, the page under
  /// it sliding back), which all come to rest at nothing.
  static Rect? _settledPlaceOf(GlobalKey key, RenderBox overlay) {
    final place = _placeOf(key, overlay);
    final box = key.currentContext?.findRenderObject();
    if (place == null || box == null) return null;
    var shift = Offset.zero;
    for (var node = box.parent; node != null; node = node.parent) {
      if (node == overlay) break;
      if (node is RenderFractionalTranslation && node.hasSize) {
        shift += Offset(
          node.translation.dx * node.size.width,
          node.translation.dy * node.size.height,
        );
      }
    }
    return place.rect.shift(-shift);
  }

  /// [keys] in the order they are painted under [root]: the last is on top.
  static List<GlobalKey> _paintOrder(
    Iterable<GlobalKey> keys,
    RenderObject root,
  ) {
    final byBox = <RenderObject, GlobalKey>{
      for (final k in keys)
        if (k.currentContext?.findRenderObject() case final RenderObject r)
          r: k,
    };
    final order = <GlobalKey>[];
    void visit(RenderObject node) {
      if (byBox[node] case final k?) order.add(k);
      if (order.length < byBox.length) node.visitChildren(visit);
    }

    visit(root);
    return order;
  }

  /// Flies the cards at [from] (boxes by hash, taken before the page
  /// changed) to their places on [page], which are hidden until they land.
  /// Their places on [fromPage] are hidden while they fly, so a card is
  /// never seen twice (one going down with a sheet). [path]: carried over a
  /// sheet's edge; into a sheet ([FlightPath.into]) it flies to where its
  /// place will be once the sheet is up, not after the sheet as it slides;
  /// [settled]: to where its place will be once the pages stop sliding (a
  /// page pushed over another, or popped).
  /// It lands turned as its place is, and the cards lie on top of each
  /// other in the order they are drawn there. Call [boxes] for [fromPage]
  /// first. Call before the change that builds [page]; the flights
  /// start once it has laid out. A card without a place on [page] does not
  /// fly. Whether any card flies.
  bool carry(
    BuildContext context, {
    required Map<String, Rect> from,
    required String page,
    String? fromPage,
    FlightPath? path,
    bool settled = false,
    required SelectableCredentialInstance? Function(String hash) card,
    required List<Credential> wallet,
    Duration duration = const Duration(milliseconds: 560),
  }) {
    if (from.isEmpty || MediaQuery.disableAnimationsOf(context)) return false;
    final keys = {for (final h in from.keys) h: of(page, h)};
    final leaving = {
      if (fromPage != null)
        for (final h in from.keys) h: of(fromPage, h),
    };
    Flight.hide([...keys.values, ...leaving.values]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final overlay =
          Overlay.of(context, rootOverlay: true).context.findRenderObject()
              as RenderBox?;
      // On top of each other as they will lie where they land, so none
      // changes places as it is put down.
      final painted = overlay == null
          ? keys.values.toList()
          : _paintOrder(keys.values, overlay);
      int zOf(GlobalKey k) {
        final i = painted.indexOf(k);
        return i < 0 ? painted.length : i;
      }

      for (final MapEntry(key: hash, value: rect) in from.entries) {
        final to = keys[hash]!;
        final c = card(hash);
        if (c == null || to.currentContext == null || !context.mounted) {
          Flight.show([to, ?leaving[hash]]);
          continue;
        }
        final landing = overlay == null ? null : _placeOf(to, overlay);
        Flight.start(
          context,
          fromRect: rect,
          to: path?.into ?? false
              ? (overlay) => Sheet.settledBox(to, overlay)
              : settled
              ? (overlay) => _settledPlaceOf(to, overlay)
              : (overlay) => _placeOf(to, overlay)?.rect,
          keys: FlightKey.carry(
            lift: 0.2,
            hold: 0.8,
            startTurn: fromPage == null ? 0 : _turns[(fromPage, hash)] ?? 0,
            endTurn: landing?.turn ?? 0,
          ),
          path: path,
          duration: duration,
          lift: Flight.liftCarried,
          shadow: Flight.shadowCarried,
          radius: const BorderRadius.all(Radius.circular(4)),
          hide: [to, ?leaving[hash]],
          z: zOf(to),
          copyKey: Key("spot_flight_$hash"),
          copy: (context, frame) => CredentialCardArt(
            credential: sharedCardFor(c, wallet),
            width: frame.size.width,
          ),
        );
      }
    });
    return true;
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
