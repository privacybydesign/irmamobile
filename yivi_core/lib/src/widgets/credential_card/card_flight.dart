import "package:material_ui/material_ui.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/yivi_palette.dart";
import "card_art/credential_card_art.dart";

/// Where a flying card lands, in [overlay]'s coordinates; null while it is
/// not on screen. Asked every frame, so the card follows a target that moves
/// (a list that settles, a page behind a sheet that slides away). [first] is
/// true on the first ask.
typedef CardFlightTarget =
    Rect? Function(RenderBox overlay, {required bool first});

/// A copy of a card that flies, in the root overlay, from where it is on
/// screen to where it lands: from the issuance success screen into the data
/// tab, or from the sheet a card was added in into its spot on the share
/// screen. It turns a little and carries a green check that fades as it goes.
///
/// One flight at a time; the screens it flies between hide their own copy of
/// the card meanwhile.
class CardFlight {
  CardFlight._();

  static const flight = Duration(milliseconds: 760);
  static const curve = Cubic(0.3, 0.9, 0.25, 1);

  static OverlayEntry? _entry;

  static bool get isFlying => _entry != null;

  /// The [CardFlightLanding] a card is flying to: it hides its own copy
  /// until the card has landed.
  static final landing = ValueNotifier<GlobalKey?>(null);

  /// Starts a flight of [card] from the box of [source] to [target]. Returns
  /// false without doing anything when it cannot: no source on screen, or a
  /// flight under way.
  ///
  /// [total] is how long the overlay stays, at least [flight] (the flight
  /// itself). With [curtain] a cover in the page colour fades out over
  /// [curtainDuration] under the card, hiding a switch of screens. [wrap]
  /// wraps the flying card, e.g. to tuck it under the card below its place.
  /// [onTick] is told how far the flight is on every frame; [onDone] runs
  /// once the overlay is gone.
  ///
  /// With reduce motion on no card flies; only the curtain fades.
  static bool start(
    BuildContext context, {
    required GlobalKey source,
    required CardFlightTarget target,
    required schemaless.Credential card,
    Duration? total,
    bool curtain = false,
    Duration curtainDuration = const Duration(milliseconds: 460),
    Widget Function(Widget card, Animation<double> clock)? wrap,
    void Function(Duration elapsed)? onTick,
    VoidCallback? onDone,
    Key? cardKey,
    GlobalKey? landingKey,
  }) {
    final box = source.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _entry != null) return false;

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final from =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    _entry = OverlayEntry(
      builder: (_) => _FlightOverlay(
        card: card,
        from: from,
        target: target,
        duration: flight,
        total: reduceMotion
            ? (curtain ? curtainDuration : Duration.zero)
            : (total == null || total < flight ? flight : total),
        curtain: curtain,
        curtainDuration: curtainDuration,
        reduceMotion: reduceMotion,
        wrap: wrap,
        onTick: onTick,
        cardKey: cardKey,
        onDone: () {
          _entry?.remove();
          _entry = null;
          if (landing.value == landingKey) landing.value = null;
          onDone?.call();
        },
      ),
    );
    if (landingKey != null) landing.value = landingKey;
    overlay.insert(_entry!);
    return true;
  }

  /// The rect of [key]'s box in [overlay]'s coordinates, for a [target] that
  /// is a widget on screen.
  static Rect? rectOf(GlobalKey key, RenderBox overlay) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  /// Ends a flight at once, without its [onDone], e.g. between tests.
  static void reset() {
    _entry?.remove();
    _entry = null;
    landing.value = null;
  }
}

/// Where a [CardFlight] can land: marks its [child] with [landingKey] (pass
/// it to [CardFlight.start] as the target and as its `landingKey`), and hides
/// the child while a card flies to it, so the card does not show twice.
class CardFlightLanding extends StatelessWidget {
  final GlobalKey landingKey;
  final Widget child;

  const CardFlightLanding({
    super.key,
    required this.landingKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<GlobalKey?>(
    valueListenable: CardFlight.landing,
    child: KeyedSubtree(key: landingKey, child: child),
    builder: (context, target, child) =>
        Opacity(opacity: target == landingKey ? 0 : 1, child: child),
  );
}

class _FlightOverlay extends StatefulWidget {
  final schemaless.Credential card;
  final Rect from;
  final CardFlightTarget target;
  final Duration duration;
  final Duration total;
  final bool curtain;
  final Duration curtainDuration;
  final bool reduceMotion;
  final Widget Function(Widget card, Animation<double> clock)? wrap;
  final void Function(Duration elapsed)? onTick;
  final VoidCallback onDone;
  final Key? cardKey;

  const _FlightOverlay({
    required this.card,
    required this.from,
    required this.target,
    required this.duration,
    required this.total,
    required this.curtain,
    required this.curtainDuration,
    required this.reduceMotion,
    required this.wrap,
    required this.onTick,
    required this.onDone,
    required this.cardKey,
  });

  @override
  State<_FlightOverlay> createState() => _FlightOverlayState();
}

class _FlightOverlayState extends State<_FlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.total,
  );

  Rect? _to;

  @override
  void initState() {
    super.initState();
    final onTick = widget.onTick;
    if (onTick != null) _clock.addListener(() => onTick(_elapsed));
    if (widget.total == Duration.zero) {
      // Nothing to show: done after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
    } else {
      _clock.forward().whenComplete(widget.onDone);
    }
  }

  Duration get _elapsed => widget.total * _clock.value;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  double _progress(Duration of) => of == Duration.zero
      ? 1
      : (_elapsed.inMicroseconds / of.inMicroseconds).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final overlayBox = context.findRenderObject() as RenderBox?;
          if (overlayBox != null && overlayBox.hasSize) {
            _to = widget.target(overlayBox, first: _to == null) ?? _to;
          }
          final t = CardFlight.curve.transform(_progress(widget.duration));
          final rect = Rect.lerp(widget.from, _to ?? widget.from, t)!;

          Widget card = Transform.rotate(
            angle: -0.035 * (1 - t),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CredentialCardArt(credential: widget.card, width: rect.width),
                Positioned(
                  right: -12,
                  top: -16,
                  child: Opacity(
                    opacity: 1 - t,
                    // The badge shrinks with the card, so a card that lands
                    // in a small spot does not end under a large check.
                    child: Transform.scale(
                      scale: (rect.width / widget.from.width).clamp(0.3, 1.0),
                      alignment: Alignment.topRight,
                      child: _CheckBadge(border: palette.background),
                    ),
                  ),
                ),
              ],
            ),
          );
          final wrap = widget.wrap;
          if (wrap != null) card = wrap(card, _clock);

          return Stack(
            children: [
              if (widget.curtain)
                Positioned.fill(
                  child: ColoredBox(
                    color: palette.background.withValues(
                      alpha: 1 - _progress(widget.curtainDuration),
                    ),
                  ),
                ),
              if (!widget.reduceMotion)
                Positioned(
                  key: widget.cardKey,
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  child: card,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The green check on the received card.
class _CheckBadge extends StatelessWidget {
  final Color border;

  const _CheckBadge({required this.border});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF00973A),
      shape: BoxShape.circle,
      border: Border.all(color: border, width: 4),
    ),
    child: const Icon(Icons.check, color: Colors.white, size: 30),
  );
}
