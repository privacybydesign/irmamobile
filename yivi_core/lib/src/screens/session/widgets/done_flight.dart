import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_motion.dart";
import "../../../util/laid_out_box.dart";
import "../../../widgets/flight/yivi_flight.dart";

/// The flight from the share screen into the done screen: when the user
/// shares, [capture] notes where each card's picture and the message are;
/// on its first frame the done screen [land]s them: each picture flies to
/// its place in the pile (or the stack on a signed message), the bottom card
/// first, and the message to the paper.
class DoneFlight {
  DoneFlight._();

  static _Captured? _captured;

  /// Notes where [cards] (a picture's key and its card's hash) and the message at
  /// [messageKey] are, in the overlay's coordinates. A card scrolled out of
  /// view starts just past that edge of the screen.
  static void capture(
    BuildContext context, {
    GlobalKey? messageKey,
    List<(GlobalKey, String)> cards = const [],
  }) {
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox?;
    if (overlay == null || !overlay.hasSize) return;
    final height = overlay.size.height;
    Rect clamp(Rect r) => r.top < -r.height
        ? r.shift(Offset(0, -r.height - r.top))
        : r.top > height
        ? r.shift(Offset(0, height - r.top))
        : r;
    _captured = _Captured(
      cards: [
        for (final (key, hash) in cards)
          if (key.currentContext.rectIn(overlay) case final r?)
            (hash, clamp(r)),
      ],
      message: messageKey?.currentContext.rectIn(overlay),
    );
  }

  /// Flies what was captured into the done screen: [cards] are the pile's
  /// pictures (the key of their unturned box, the card's hash, how high they
  /// lie in the pile: the bottom one flies first, and their turn), [paper]
  /// the message. 560 ms each, 70 ms apart. Returns the places that fly
  /// (they show as they land); the others are up to the caller.
  static Set<GlobalKey> land(
    BuildContext context, {
    required List<
      ({GlobalKey key, String hash, int z, double turn, Widget picture})
    >
    cards,
    GlobalKey? paper,
    Widget? paperCopy,
  }) {
    final captured = _captured;
    _captured = null;
    final flying = <GlobalKey>{};
    if (captured == null) return flying;
    final used = <int>{};
    final pairs =
        <
          (
            Rect,
            ({GlobalKey key, String hash, int z, double turn, Widget picture}),
          )
        >[];
    for (final c in cards) {
      final i = captured.cards.indexed
          .where((e) => !used.contains(e.$1) && e.$2.$1 == c.hash)
          .map((e) => e.$1)
          .firstOrNull;
      if (i == null) continue;
      used.add(i);
      pairs.add((captured.cards[i].$2, c));
    }
    // The bottom card first: each lands on top of the one before.
    pairs.sort((a, b) => a.$2.z.compareTo(b.$2.z));
    const duration = Duration(milliseconds: 560);
    for (final (n, (from, c)) in pairs.indexed) {
      flying.add(c.key);
      YiviFlight.start(
        context,
        fromRect: from,
        to: YiviFlight.boxOf(c.key),
        // Ends on the place's own turn; the key is on its unturned box.
        keys: [
          const FlightKey(0, FlightKey.start),
          FlightKey(1, FlightKey.end, turn: c.turn),
        ],
        duration: duration,
        delay: Duration(milliseconds: 60 + n * 70),
        curve: YiviMotion.carry,
        hide: [c.key],
        z: 8 + c.z,
        copy: (context, frame) => SizedBox.fromSize(
          size: frame.size,
          child: FittedBox(fit: BoxFit.fill, child: c.picture),
        ),
      );
    }
    final message = captured.message;
    if (message != null && paper != null && paperCopy != null) {
      flying.add(paper);
      YiviFlight.start(
        context,
        fromRect: message,
        to: YiviFlight.boxOf(paper),
        keys: const [
          FlightKey(0, FlightKey.start),
          FlightKey(1, FlightKey.end),
        ],
        duration: duration,
        curve: YiviMotion.carry,
        hide: [paper],
        copy: (context, frame) => SizedBox.fromSize(
          size: frame.size,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: double.infinity,
              child: SizedBox(width: frame.size.width, child: paperCopy),
            ),
          ),
        ),
      );
    }
    return flying;
  }

  /// Whether something was captured to land.
  static bool get pending => _captured != null;

  /// Forgets a capture, e.g. between tests.
  static void reset() => _captured = null;
}

class _Captured {
  final List<(String, Rect)> cards;
  final Rect? message;

  const _Captured({required this.cards, required this.message});
}
