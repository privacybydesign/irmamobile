import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../data/wallet/wallet_transition.dart";
import "activity_entry.dart";
import "widgets/activity_detail_parts.dart";

/// Where a card of an activity entry is: in the row's pile ([pile]) or in a
/// tile of the details. [ActivityFlight] measures it every frame, and hides
/// it while the entry is in flight (the flight draws it instead).
class ActivityFlightSlot extends StatefulWidget {
  final String entryKey;
  final int index;
  final bool pile;
  final Widget child;

  const ActivityFlightSlot({
    super.key,
    required this.entryKey,
    required this.index,
    required this.pile,
    required this.child,
  });

  @override
  State<ActivityFlightSlot> createState() => _ActivityFlightSlotState();
}

class _ActivityFlightSlotState extends State<ActivityFlightSlot> {
  (String, int, bool) get _id => (widget.entryKey, widget.index, widget.pile);

  @override
  void didUpdateWidget(ActivityFlightSlot old) {
    super.didUpdateWidget(old);
    final oldId = (old.entryKey, old.index, old.pile);
    if (ActivityFlight._slots[oldId] == context) {
      ActivityFlight._slots.remove(oldId);
    }
  }

  @override
  void dispose() {
    if (ActivityFlight._slots[_id] == context) {
      ActivityFlight._slots.remove(_id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ActivityFlight._slots[_id] = context;
    return _HiddenInFlight(entryKey: widget.entryKey, child: widget.child);
  }
}

/// The logo on a row's pile, for [ActivityFlight]: measured and hidden like
/// an [ActivityFlightSlot], and drawn by the flight over the cards.
class ActivityFlightLogoSlot extends StatefulWidget {
  final String entryKey;
  final Widget child;

  const ActivityFlightLogoSlot({
    super.key,
    required this.entryKey,
    required this.child,
  });

  @override
  State<ActivityFlightLogoSlot> createState() => _ActivityFlightLogoSlotState();
}

class _ActivityFlightLogoSlotState extends State<ActivityFlightLogoSlot> {
  @override
  void didUpdateWidget(ActivityFlightLogoSlot old) {
    super.didUpdateWidget(old);
    if (ActivityFlight._logos[old.entryKey] == context) {
      ActivityFlight._logos.remove(old.entryKey);
    }
  }

  @override
  void dispose() {
    if (ActivityFlight._logos[widget.entryKey] == context) {
      ActivityFlight._logos.remove(widget.entryKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ActivityFlight._logos[widget.entryKey] = context;
    return _HiddenInFlight(entryKey: widget.entryKey, child: widget.child);
  }
}

/// Its child takes its place but does not show while [entryKey] is in
/// flight.
class _HiddenInFlight extends StatelessWidget {
  final String entryKey;
  final Widget child;

  const _HiddenInFlight({required this.entryKey, required this.child});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: ActivityFlight.flying,
    builder: (context, flying, child) => Visibility(
      visible: flying != entryKey,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: child!,
    ),
    child: child,
  );
}

/// The flight of an activity entry's cards between the row's pile and the
/// tiles of its details, in one overlay, driven by the details route's
/// animation.
///
/// It replaces a `Hero` per card: heroes fly in the details' tree order, so
/// the cards landed in the wrong layer order and jumped on the last frame,
/// and the logo on the pile, which is not a hero, ended up under them. Here
/// the overlay draws the pile as the pile does, back to front: the cards
/// past the third, then the third, second and first, then the logo. Each
/// card goes from its pile slot to its tile slot, both measured every frame
/// (so a pulled-down page and a moving list are followed), with the same
/// timing and stagger as before.
class ActivityFlight {
  ActivityFlight._();

  /// The entry whose cards are in flight; their slots hide meanwhile.
  static final flying = ValueNotifier<String?>(null);

  static final _slots = <(String, int, bool), BuildContext>{};
  static final _logos = <String, BuildContext>{};

  static OverlayEntry? _entry;
  static Animation<double>? _animation;
  static ActivityEntry? _flown;
  static OverlayState? _overlay;

  /// Flies [entry]'s cards with the details route's [animation], in the
  /// root overlay above that route. Nothing flies without a pile to fly
  /// from (opened from elsewhere, or the row is not built) or with reduced
  /// motion: then the tiles just fade in and out.
  static void start(
    BuildContext context,
    ActivityEntry entry,
    Animation<double> animation,
  ) {
    stop();
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (entry.cards.isEmpty || _rectOf(_slots[(entry.key, 0, true)]) == null) {
      return;
    }
    _overlay = Overlay.of(context, rootOverlay: true);
    _flown = entry;
    _animation = animation..addStatusListener(_onStatus);
    if (animation.status == AnimationStatus.forward ||
        animation.status == AnimationStatus.reverse) {
      _show();
    }
  }

  /// Ends any flight (the details went away).
  static void stop() {
    _animation?.removeStatusListener(_onStatus);
    _animation = null;
    _hide();
    _flown = null;
    _overlay = null;
  }

  static void _onStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward || AnimationStatus.reverse:
        _show();
      case AnimationStatus.completed:
        _hide();
      case AnimationStatus.dismissed:
        stop();
    }
  }

  static void _show() {
    final entry = _flown;
    final overlay = _overlay;
    final animation = _animation;
    if (entry == null || overlay == null || animation == null) return;
    if (_entry == null) {
      _entry = OverlayEntry(
        builder: (_) => _FlightOverlay(entry: entry, animation: animation),
      );
      overlay.insert(_entry!);
    }
    flying.value = entry.key;
  }

  /// The real pile and tiles show from this frame on, where the overlay
  /// last drew them.
  static void _hide() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    flying.value = null;
  }

  /// Where [context]'s box is on the screen, with its transforms (a pile
  /// card is scaled down), or null when it is not laid out.
  static Rect? _rectOf(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
  }

  static Rect? pileRect(String key, int index) =>
      _rectOf(_slots[(key, index, true)]);

  static Rect? tileRect(String key, int index) =>
      _rectOf(_slots[(key, index, false)]);

  static Rect? logoRect(String key) => _rectOf(_logos[key]);
}

/// The pile in flight, back to front as the pile draws it.
class _FlightOverlay extends StatelessWidget {
  final ActivityEntry entry;
  final Animation<double> animation;

  const _FlightOverlay({required this.entry, required this.animation});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // The overlay itself was laid out before this entry was put in it.
    final overlayBox = Overlay.of(context).context.findRenderObject();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final value = animation.value;
          // Global rects into the overlay's own coordinates.
          final origin = overlayBox is RenderBox && overlayBox.hasSize
              ? overlayBox.localToGlobal(Offset.zero)
              : Offset.zero;
          Rect local(Rect r) => r.shift(-origin);

          final n = entry.cards.length;
          final cards = <Widget>[
            // Past the third first (the back), then the third, second, first.
            for (var i = n - 1; i >= 3; i--) _card(i, value, local),
            for (var i = (n < 3 ? n : 3) - 1; i >= 0; i--)
              _card(i, value, local),
          ];

          final logoRect = ActivityFlight.logoRect(entry.key);
          // The logo fades with the row around it (PushAway), over the cards.
          final logoOpacity = 1 - const Interval(0, 0.5).transform(value);
          return Stack(
            children: [
              ...cards,
              if (logoRect != null)
                Positioned.fromRect(
                  key: const Key("activity_flight_logo"),
                  rect: local(logoRect),
                  child: Opacity(
                    opacity: logoOpacity,
                    child: OverflowBox(
                      // As on the pile: the logo at its own size, its ring
                      // around it.
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: ActivityPartyLogo(
                        party: entry.party,
                        size: ActivityPartyLogo.pileSize,
                        circle: true,
                        ring: palette.surface,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(int i, double value, Rect Function(Rect) local) {
    final pile = ActivityFlight.pileRect(entry.key, i);
    final tile = ActivityFlight.tileRect(entry.key, i) ?? pile;
    if (pile == null || tile == null) return const SizedBox.shrink();
    final e = WalletTransition.staggered(value, i);
    final rect = Rect.lerp(pile, tile, e)!;
    // The cards past the third come out from behind the pile, and are gone
    // again by the time they reach it.
    final opacity = i < 3
        ? 1.0
        : WalletTransition.closing
        ? 1 - const Interval(0.6, 1).transform(1 - value)
        : e.clamp(0.0, 1.0);
    final card = entry.cards[i];
    return Positioned.fromRect(
      key: ValueKey(("activity_flight_card", i)),
      rect: local(rect),
      child: Opacity(
        opacity: opacity,
        child: CredentialCardArt(
          credential: card.art,
          width: rect.width,
          greyedOut: card.deleted,
        ),
      ),
    );
  }
}
