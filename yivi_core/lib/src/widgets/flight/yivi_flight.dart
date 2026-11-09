import "package:flutter/foundation.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "../../theme/yivi_motion.dart";
import "../../util/laid_out_box.dart";

/// Where a flying copy is at one moment: a box worked out from where it
/// started ([from]) and where it lands ([to]), lifted or not, turned, faded.
///
/// The beats between two keys each ease on their own (as CSS keyframes do),
/// with the flight's curve.
class FlightKey {
  /// How far through the flight, 0..1.
  final double at;

  /// The box at [at], from the start and the end box.
  final Rect Function(Rect from, Rect to) place;

  /// Picked up: a little bigger, 4 higher, with a shadow.
  final bool lifted;

  /// Turned, in radians.
  final double turn;

  /// The copy's opacity.
  final double opacity;

  /// The opacity of the part of a copy that folds away while it is carried
  /// (a card tile's bottom strip); the copy's builder decides what that is.
  final double strip;

  const FlightKey(
    this.at,
    this.place, {
    this.lifted = false,
    this.turn = 0,
    this.opacity = 1,
    this.strip = 1,
  });

  static Rect start(Rect from, Rect to) => from;
  static Rect end(Rect from, Rect to) => to;

  /// The keys of a card carried from one place to another in three beats:
  /// picked up where it is, carried while lifted, put down; [lift] and [hold]
  /// are where the beats meet.
  static List<FlightKey> carry({
    double lift = 0.22,
    double hold = 0.82,
    double startOpacity = 1,
    double startTurn = 0,
  }) => [
    FlightKey(0, start, opacity: startOpacity, turn: startTurn),
    FlightKey(lift, start, lifted: true, turn: startTurn),
    FlightKey(hold, end, lifted: true),
    const FlightKey(1, end),
  ];
}

/// What a copy's builder is told on every frame.
class FlightFrame {
  /// The copy's size now.
  final Size size;

  /// See [FlightKey.strip].
  final double strip;

  /// How far through the flight, 0..1, not eased.
  final double t;

  const FlightFrame(this.size, this.strip, this.t);
}

/// The box a copy flies to, in the overlay's coordinates; asked on every
/// frame, so the copy follows a place that still moves (a sheet that slides
/// up, a list that settles). Null while it is not on screen: the last known
/// box stands in.
typedef FlightTarget = Rect? Function(RenderBox overlay);

/// A copy of something that flies, in the root overlay, from where it is to
/// where it lands: a card from its row into a sheet and back, a logo into a
/// sheet, the cards into the done screen.
///
/// The places it flies between are hidden while it flies ([FlightSpot]s with
/// the [hide] keys). When it lands, those show first and the copy goes two
/// frames later, so there is never a frame with neither. With reduce motion
/// on nothing flies: [onLanded] runs at once.
class YiviFlight {
  YiviFlight._();

  /// The lift of a card in a sheet.
  static const liftCard = 1.03;

  /// The lift of a card carried between a page and a sheet.
  static const liftCarried = 1.05;

  static final _hidden = _HiddenKeys();
  static final _entries = <OverlayEntry>[];

  /// Whether a copy is flying.
  static bool get isFlying => _entries.isNotEmpty;

  /// The keys hidden right now, for [FlightSpot].
  static ValueListenable<Set<Key>> get hidden => _hidden;

  /// Hides [keys] until [show]. For a place that waits for a flight that
  /// starts a little later (a card that lands once its sheet is gone).
  static void hide(Iterable<Key> keys) =>
      _hidden.value = {..._hidden.value, ...keys};

  /// Shows [keys] again.
  static void show(Iterable<Key> keys) =>
      _hidden.value = {..._hidden.value}..removeAll(keys);

  /// Starts a flight of [copy] from [from] (a key on screen, or a box in the
  /// overlay's coordinates) to [to]. Returns false, calling [onLanded] at
  /// once, when it cannot fly (no start on screen, reduce motion).
  ///
  /// [copy] builds the flying copy at the size of the frame. [z] orders
  /// copies that fly at the same time: higher is on top.
  static bool start(
    BuildContext context, {
    GlobalKey? from,
    Rect? fromRect,
    required FlightTarget to,
    required Widget Function(BuildContext context, FlightFrame frame) copy,
    required List<FlightKey> keys,
    required Duration duration,
    Duration delay = Duration.zero,
    Curve curve = YiviMotion.carry,
    double lift = liftCard,
    BorderRadius radius = BorderRadius.zero,
    BoxShadow shadow = const BoxShadow(
      color: Color(0x38102846),
      blurRadius: 34,
      offset: Offset(0, 14),
    ),
    Iterable<Key> hide = const [],
    int z = 0,
    VoidCallback? onLanded,
    Key? copyKey,
    Widget Function(Widget copy, Animation<double> clock)? wrap,
    void Function(Duration elapsed)? onTick,
    Widget Function(Duration elapsed)? backdrop,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final start =
        fromRect ??
        (overlayBox == null ? null : from?.currentContext.rectIn(overlayBox));
    if (start == null || MediaQuery.disableAnimationsOf(context)) {
      onLanded?.call();
      return false;
    }

    final hiding = hide.toSet();
    YiviFlight.hide(hiding);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flying(
        z: z,
        from: start,
        to: to,
        copy: copy,
        keys: keys,
        duration: duration,
        delay: delay,
        curve: curve,
        lift: lift,
        radius: radius,
        shadow: shadow,
        copyKey: copyKey,
        wrap: wrap,
        onTick: onTick,
        backdrop: backdrop,
        onDone: () {
          // Show the places first, then take the copy away two frames later.
          show(hiding);
          onLanded?.call();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              entry.remove();
              _entries.remove(entry);
            });
            SchedulerBinding.instance.scheduleFrame();
          });
          SchedulerBinding.instance.scheduleFrame();
        },
      ),
    );
    // Above every copy with a lower z.
    final above = _entries.where((e) => (_zOf[e] ?? 0) > z).firstOrNull;
    _zOf[entry] = z;
    overlay.insert(entry, below: above);
    _entries.add(entry);
    return true;
  }

  static final _zOf = Expando<int>();

  /// The box of [key] in the overlay's coordinates, for a [FlightTarget].
  static FlightTarget boxOf(GlobalKey key) =>
      (overlay) => key.currentContext.rectIn(overlay);

  /// Ends every flight at once, e.g. between tests.
  static void reset() {
    for (final e in _entries) {
      e.remove();
    }
    _entries.clear();
    _hidden.value = const {};
  }
}

/// A place a [YiviFlight] flies from or to: hides its [child] while its
/// [flightKey] is hidden, and marks it with that key so the flight can find
/// its box.
class FlightSpot extends StatelessWidget {
  final GlobalKey flightKey;
  final Widget child;

  const FlightSpot({super.key, required this.flightKey, required this.child});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<Key>>(
    valueListenable: YiviFlight.hidden,
    child: KeyedSubtree(key: flightKey, child: child),
    builder: (context, hidden, child) =>
        Opacity(opacity: hidden.contains(flightKey) ? 0 : 1, child: child),
  );
}

class _Flying extends StatefulWidget {
  final int z;
  final Rect from;
  final FlightTarget to;
  final Widget Function(BuildContext context, FlightFrame frame) copy;
  final List<FlightKey> keys;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double lift;
  final BorderRadius radius;
  final BoxShadow shadow;
  final Key? copyKey;
  final VoidCallback onDone;
  final Widget Function(Widget copy, Animation<double> clock)? wrap;
  final void Function(Duration elapsed)? onTick;
  final Widget Function(Duration elapsed)? backdrop;

  const _Flying({
    required this.z,
    required this.from,
    required this.to,
    required this.copy,
    required this.keys,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.lift,
    required this.radius,
    required this.shadow,
    required this.copyKey,
    required this.onDone,
    this.wrap,
    this.onTick,
    this.backdrop,
  });

  @override
  State<_Flying> createState() => _FlyingState();
}

class _FlyingState extends State<_Flying> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  Rect? _to;
  bool _done = false;

  Duration get _elapsed => (widget.delay + widget.duration) * _clock.value;

  @override
  void initState() {
    super.initState();
    final onTick = widget.onTick;
    if (onTick != null) _clock.addListener(() => onTick(_elapsed));
    _clock.forward().whenComplete(() {
      if (_done) return;
      _done = true;
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// How far through the flight itself (after the delay), 0..1.
  double get _t {
    final total = widget.delay + widget.duration;
    final elapsed = total * _clock.value;
    if (elapsed <= widget.delay) return 0;
    return ((elapsed - widget.delay).inMicroseconds /
            widget.duration.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final overlay = context.findRenderObject() as RenderBox?;
        if (overlay != null && overlay.hasSize) {
          _to = widget.to(overlay) ?? _to;
        } else {
          // The overlay is not laid out yet on the first frame: ask again.
          SchedulerBinding.instance.addPostFrameCallback(
            (_) => mounted ? setState(() {}) : null,
          );
        }
        final to = _to ?? widget.from;
        final frame = _at(_t, widget.from, to);
        final up = frame.lifted;
        final scale = 1 + (widget.lift - 1) * up;
        Widget copy = widget.copy(
          context,
          FlightFrame(frame.rect.size, frame.strip, _t),
        );
        final wrap = widget.wrap;
        if (wrap != null) copy = wrap(copy, _clock);
        final backdrop = widget.backdrop;
        return Stack(
          children: [
            if (backdrop != null) Positioned.fill(child: backdrop(_elapsed)),
            Positioned(
              key: widget.copyKey,
              left: frame.rect.left,
              top: frame.rect.top - 4 * up,
              width: frame.rect.width,
              height: frame.rect.height,
              child: Opacity(
                opacity: frame.opacity.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: frame.turn,
                  child: Transform.scale(
                    scale: scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: widget.radius,
                        boxShadow: up == 0 ? null : [widget.shadow.scale(up)],
                      ),
                      child: copy,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  _Frame _at(double t, Rect from, Rect to) {
    final keys = widget.keys;
    var i = 0;
    while (i < keys.length - 2 && t > keys[i + 1].at) {
      i++;
    }
    final a = keys[i], b = keys[i + 1];
    final span = b.at - a.at;
    final local = span <= 0 ? 1.0 : ((t - a.at) / span).clamp(0.0, 1.0);
    final e = widget.curve.transform(local);
    double lerp(double x, double y) => x + (y - x) * e;
    return _Frame(
      rect: Rect.lerp(a.place(from, to), b.place(from, to), e)!,
      lifted: lerp(a.lifted ? 1 : 0, b.lifted ? 1 : 0),
      turn: lerp(a.turn, b.turn),
      opacity: lerp(a.opacity, b.opacity),
      strip: lerp(a.strip, b.strip),
    );
  }
}

class _Frame {
  final Rect rect;
  final double lifted;
  final double turn;
  final double opacity;
  final double strip;

  const _Frame({
    required this.rect,
    required this.lifted,
    required this.turn,
    required this.opacity,
    required this.strip,
  });
}

/// The hidden keys. Changed during a build (a sheet's initState hiding the
/// row a card lands on), its listeners hear of it after that frame: places
/// built in that frame read the new value themselves.
class _HiddenKeys extends ChangeNotifier implements ValueListenable<Set<Key>> {
  Set<Key> _value = const {};
  bool _waiting = false;

  @override
  Set<Key> get value => _value;

  set value(Set<Key> keys) {
    if (setEquals(keys, _value)) return;
    _value = keys;
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_waiting) return;
    _waiting = true;
    binding.addPostFrameCallback((_) {
      _waiting = false;
      notifyListeners();
    });
    binding.scheduleFrame();
  }
}
