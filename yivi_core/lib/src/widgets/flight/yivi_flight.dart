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

  /// How high a copy carried over a sheet's edge ([FlightPath]) comes from
  /// above its place in the sheet (or rises out of it): the same for every
  /// copy, wherever it lands, so each comes down (or goes up) alike.
  static const riseHeight = 48.0;

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

/// The way a copy carried over a sheet's edge goes: one smooth curve,
/// never stopping on the way. Into a sheet it is picked up, arcs over the
/// sheet's edge and comes straight down onto its place; out of a sheet it
/// rises straight up out of its place, arcs over and comes down where it
/// lands. Its size changes during [size] (a part of the flight, 0..1).
///
/// With a path, a flight's [FlightKey]s only say how lifted, turned, faded
/// and folded the copy is; their places are not used.
class FlightPath {
  /// Into a sheet ([to] is in the sheet), or out of one.
  final bool into;

  /// When the copy takes on its new size.
  final Interval size;

  /// One curve over the whole way: it sets off gently as it is picked up and
  /// settles slowly as it is put down, with no stop or jolt between.
  final Curve curve;

  const FlightPath.into({
    this.size = const Interval(0, 0.5),
    this.curve = const Cubic(0.4, 0, 0.2, 1),
  }) : into = true;

  const FlightPath.outOf({
    this.size = const Interval(0.5, 1),
    this.curve = const Cubic(0.4, 0, 0.2, 1),
  }) : into = false;

  /// The box at [t] (not eased): a cubic Bézier through the boxes' top-left
  /// corners, its handle at the sheet's end straight above that end
  /// (2 × [FlightKey.riseHeight]), so the copy comes down onto its place in
  /// the sheet, or rises out of it, upright, from over the sheet's edge.
  Rect at(double t, Rect from, Rect to) {
    final s = curve.transform(t);
    const high = 2 * FlightKey.riseHeight;
    const low = 0.5 * FlightKey.riseHeight;
    final p0 = from.topLeft, p3 = to.topLeft;
    final p1 = p0.translate(0, -(into ? low : high));
    final p2 = p3.translate(0, -(into ? high : low));
    final u = 1 - s;
    final at =
        p0 * (u * u * u) +
        p1 * (3 * u * u * s) +
        p2 * (3 * u * s * s) +
        p3 * (s * s * s);
    final grown = size.transform(t);
    return at & Size.lerp(from.size, to.size, grown)!;
  }
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

/// Steers a flight by hand ([YiviFlight.follow]): its [t] follows a gesture
/// (a sheet dragged down), and once the gesture ends it [land]s, or goes
/// [back] to where it started.
class FlightHandle {
  _FlyingState? _state;

  /// How far through the flight, 0..1.
  double get t => _state?._clock.value ?? 0;
  set t(double value) => _state?._steer(value);

  /// Flies on from where it is to the end, in the rest of its duration.
  void land() => _state?._finish(back: false);

  /// Flies back to where it started, and shows that place again.
  void back() => _state?._finish(back: true);
}

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
    FlightHandle? handle,
    GlobalKey? from,
    Rect? fromRect,
    required FlightTarget to,
    required Widget Function(BuildContext context, FlightFrame frame) copy,
    required List<FlightKey> keys,
    required Duration duration,
    Duration delay = Duration.zero,
    Curve curve = YiviMotion.carry,
    FlightPath? path,
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
        path: path,
        lift: lift,
        radius: radius,
        shadow: shadow,
        copyKey: copyKey,
        wrap: wrap,
        onTick: onTick,
        backdrop: backdrop,
        handle: handle,
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

  /// A flight steered by hand: as [start], but it stays at the start until
  /// [handle] moves it, and lands (or goes back) when told. Null when it
  /// cannot fly (no start on screen, reduce motion).
  static FlightHandle? follow(
    BuildContext context, {
    required GlobalKey from,
    required FlightTarget to,
    required Widget Function(BuildContext context, FlightFrame frame) copy,
    required List<FlightKey> keys,
    required Duration duration,
    double lift = liftCard,
    BorderRadius radius = BorderRadius.zero,
    Iterable<Key> hide = const [],
    VoidCallback? onLanded,
    Key? copyKey,
  }) {
    final handle = FlightHandle();
    final flies = start(
      context,
      handle: handle,
      from: from,
      to: to,
      copy: copy,
      keys: keys,
      duration: duration,
      // One to one with the hand; the landing eases ([FlightHandle.land]).
      curve: Curves.linear,
      lift: lift,
      radius: radius,
      hide: hide,
      onLanded: onLanded,
      copyKey: copyKey,
    );
    return flies ? handle : null;
  }

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
  final FlightPath? path;
  final double lift;
  final BorderRadius radius;
  final BoxShadow shadow;
  final Key? copyKey;
  final VoidCallback onDone;
  final Widget Function(Widget copy, Animation<double> clock)? wrap;
  final void Function(Duration elapsed)? onTick;
  final Widget Function(Duration elapsed)? backdrop;
  final FlightHandle? handle;

  const _Flying({
    required this.z,
    required this.from,
    required this.to,
    required this.copy,
    required this.keys,
    required this.duration,
    required this.delay,
    required this.curve,
    this.path,
    required this.lift,
    required this.radius,
    required this.shadow,
    required this.copyKey,
    required this.onDone,
    this.wrap,
    this.onTick,
    this.backdrop,
    this.handle,
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
    final handle = widget.handle;
    if (handle != null) {
      // Steered: it waits at the start for the hand.
      handle._state = this;
      return;
    }
    _clock.forward().whenComplete(_end);
  }

  void _end() {
    if (_done) return;
    _done = true;
    widget.handle?._state = null;
    widget.onDone();
  }

  void _steer(double t) {
    if (_done || _clock.isAnimating) return;
    _clock.value = t.clamp(0.0, 1.0);
  }

  /// On to the end, or back to the start, in the rest of the flight's time.
  void _finish({required bool back}) {
    if (_done) return;
    final target = back ? 0.0 : 1.0;
    final left = (target - _clock.value).abs();
    // Never in a snap: at least 360 ms, however little is left.
    final duration = widget.duration * left;
    const least = Duration(milliseconds: 360);
    _clock
        .animateTo(
          target,
          duration: left == 0
              ? Duration.zero
              : (duration < least ? least : duration),
          // From the hand's slow pace: no jump as it is let go.
          curve: Curves.easeInOut,
        )
        .whenComplete(_end);
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
                      // Its corners rounded all round, also where a copy
                      // cut to the frame's height has lost its own.
                      child: widget.radius == BorderRadius.zero
                          ? copy
                          : ClipRRect(borderRadius: widget.radius, child: copy),
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
    final path = widget.path;
    return _Frame(
      rect: path != null
          ? path.at(t, from, to)
          : Rect.lerp(a.place(from, to), b.place(from, to), e)!,
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
