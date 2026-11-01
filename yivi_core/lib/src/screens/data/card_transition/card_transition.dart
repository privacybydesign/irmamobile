import "dart:math";

import "package:flutter/scheduler.dart";
import "package:material_ui/material_ui.dart";

import "choreography.dart";

enum TransitionPhase { opening, open, closing }

/// One card opening from the stack, open, and closing again: its snapshot,
/// its clock and its phase. Made per tap, disposed when it is closed;
/// nothing of it is shared with the next one.
///
/// `opening → open → closing → done`. [close] also works while opening: it
/// goes on from where everything is. From the tap until it is done the
/// card's details (built by [details], the real ones) are over the home
/// screen ([OpenCardLayer]); the stack's cards follow it where they are.
///
/// While it moves a finger can take hold of it ([grab]): everything stops,
/// the card and its details follow the finger down, and let go
/// ([letGo]) it closes or opens again from there, at the finger's speed.
class CardTransition extends ChangeNotifier {
  final Choreography choreography;

  /// The details of the card: the card at the top and everything under it,
  /// as on the details page.
  final Widget Function(BuildContext context, CardTransition transition)
  details;

  /// The card at the top of [details]: closing measures where it is.
  final cardKey = GlobalKey(debugLabel: "open card");

  final VoidCallback _onDone;
  late final Ticker _ticker;

  TransitionPhase _phase = TransitionPhase.opening;

  /// The phase, for what only changes with it (not on every frame).
  final phaseListenable = ValueNotifier(TransitionPhase.opening);
  double _ms = 0;

  /// When (on the ticker's clock) the motion starts: once the layer has
  /// drawn its first frame ([ready]), so the setup frame's time does not
  /// make the cards jump. Null until then.
  Duration? _start;

  /// Whether the layer has drawn its first frame.
  bool _ready = false;

  /// At most this long the motion waits for [ready].
  static const _readyTimeout = Duration(milliseconds: 250);

  // The current stretch of the motion: from each part's progress and the
  // card's rect when it began, to open or to rest.

  /// Each part's progress when this stretch began.
  late List<double> _from = List.filled(snapshot.count, 0);

  /// Where the card was when this stretch began, and how fast it went
  /// toward where it goes (of the whole way per second).
  late Rect _fromRect = snapshot.cards[snapshot.picked];
  double _velocity = 0;

  /// The first opening: the cards go one by one. Opening again after a
  /// finger let go, all at once.
  bool _staggered = true;

  /// The card's top on the frame before: whether it still moves.
  double _lastTop = double.nan;

  /// Not done before this long into a stretch (the spring's first swing
  /// passes its end at speed).
  static const double _minMs = 250;

  /// Whether everything is within [points] of where it goes (the card) and
  /// [progress] of its end (every part).
  bool _near({required double points, required double progress}) {
    final end = _phase == TransitionPhase.closing ? 0.0 : 1.0;
    for (var i = 0; i < snapshot.count; i++) {
      if ((this.progress(i) - end).abs() > progress) return false;
    }
    final a = pickedRect, b = _toRect;
    return (a.top - b.top).abs() < points &&
        (a.left - b.left).abs() < points &&
        (a.width - b.width).abs() < points;
  }

  /// A touch: whether it should go to what is under the card instead of
  /// taking hold of it. Closing, once the card is mostly back in the stack:
  /// the touch scrolls the list, and the card lands on with it. Opening,
  /// once it has arrived: it is open from now on and the touch goes to the
  /// details.
  bool passTouch() {
    if (held) return false;
    if (_phase == TransitionPhase.closing) {
      return _list != null && progress(snapshot.picked) < 0.25;
    }
    if (_phase == TransitionPhase.opening &&
        _ms > _minMs &&
        _near(points: 4, progress: 0.03)) {
      _ticker.stop();
      _setPhase(TransitionPhase.open);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Where the details draw their card: at the target, or, once closed from
  /// open, where it was then (scrolled or pulled down).
  late Rect _detailsCard = snapshot.target;

  /// Held by a finger: each part's progress and the card's rect when it
  /// took hold, and how far it has moved since. Null when not held.
  List<double>? _held;
  late Rect _heldRect;
  double _drag = 0;

  /// The stack's list: it can scroll while a card lands (a touch then
  /// goes to it), and everything of the stack moves with it.
  final ScrollPosition? _list;
  final double _listAt;

  CardTransition({
    required this.choreography,
    required this.details,
    required TickerProvider vsync,
    required VoidCallback onDone,
    ScrollPosition? list,
  }) : _onDone = onDone,
       _list = list,
       _listAt = list != null && list.hasPixels ? list.pixels : 0 {
    _ticker = vsync.createTicker(_tick)..start();
    _list?.addListener(notifyListeners);
  }

  /// How far the stack's list has scrolled since the tap (down the screen).
  double get _scrolled =>
      _list != null && _list.hasPixels ? _listAt - _list.pixels : 0;

  /// Card [i]'s place in the stack, on screen now.
  Rect _slot(int i) => snapshot.cards[i].translate(0, _scrolled);

  TransitionSnapshot get snapshot => choreography.snapshot;
  TransitionPhase get phase => _phase;
  bool get held => _held != null;

  /// Called by the layer once it has drawn its first frame (the details
  /// built and drawn): from the next frame on, the motion runs.
  void ready() => _ready = true;

  void _tick(Duration elapsed) {
    if (_start == null) {
      if (!_ready && elapsed < _readyTimeout) return;
      _start = elapsed;
    }
    _ms = (elapsed - _start!).inMicroseconds / 1000;
    // Done once it has come to rest, not when the spring's last tremble
    // (too small to see) has gone: until then it would still hold the
    // screen.
    final top = pickedRect.top;
    final still = (top - _lastTop).abs() < 0.3;
    _lastTop = top;
    if (_ms >= choreography.settled.inMilliseconds ||
        (_ms > _minMs && still && _near(points: 0.5, progress: 0.004))) {
      _ticker.stop();
      if (_phase == TransitionPhase.opening) {
        _setPhase(TransitionPhase.open);
        notifyListeners();
        return;
      }
      if (_phase == TransitionPhase.closing) return _finish();
    }
    notifyListeners();
  }

  void _setPhase(TransitionPhase phase) {
    _phase = phase;
    phaseListenable.value = phase;
  }

  /// How far a finger pulls the card down before everything else is back
  /// as at rest (the bar, the header, the tab bar).
  double get _pullAll => snapshot.screenHeight * 0.6;

  /// Progress (0 rest, 1 open) of part [i]: a card by its place; the
  /// picked card's place is the card and its details.
  double progress(int i) {
    if (_held case final held?) {
      if (i != snapshot.picked) return held[i];
      return held[i] * (1 - (_drag / _pullAll).clamp(0.0, 1.0));
    }
    return switch (_phase) {
      TransitionPhase.opening =>
        _staggered
            ? choreography.opening(i, _ms)
            : choreography.reopening(i, _ms, _from[i]),
      TransitionPhase.open => 1,
      TransitionPhase.closing => choreography.closing(i, _ms, _from[i]),
    };
  }

  /// Where the picked card is.
  Rect get pickedRect {
    if (held) {
      // Up only a little, against a resistance.
      final dy = _drag >= 0 ? _drag : _drag * 0.3;
      return _heldRect.translate(0, dy);
    }
    return switch (_phase) {
      TransitionPhase.open => _detailsCard,
      _ => Rect.lerp(_fromRect, _toRect, _cardSpring)!,
    };
  }

  /// Where the card goes in this stretch: in the details, or its place in
  /// the stack.
  Rect get _toRect =>
      _phase == TransitionPhase.closing ? _slot(snapshot.picked) : _detailsCard;

  double get _cardSpring => choreography.spring(_ms, velocity: _velocity);

  /// Where the details draw their card now.
  Rect get detailsCard => _detailsCard;

  /// How far card [i] of the stack (below the picked one) has fallen: as
  /// the choreography says, and never above the picked card as it lands
  /// with its bounce or is pulled down (it pushes them down instead).
  double fall(int i) {
    final landing = pickedRect.top - _slot(snapshot.picked).top;
    return max(choreography.pose(i, progress(i)).dy, landing);
  }

  /// The card just below the picked one, where it is now (null: none).
  Rect? get nextCard {
    final next = snapshot.picked + 1;
    if (next >= snapshot.count) return null;
    return _slot(next).translate(0, fall(next));
  }

  /// The top of the card just below the picked one, as it falls: the
  /// picked card and its details show above it, never over it.
  double get revealLine => nextCard?.top ?? snapshot.screenHeight;

  double get headerOpacity => choreography.headerOpacity(
    picked: progress(snapshot.picked),
    top: progress(snapshot.firstSeen),
  );

  /// How far the bar's buttons have handed over to the details' ✕.
  double get barHandoff => progress(snapshot.picked).clamp(0.0, 1.0);

  /// Starts a stretch of the motion toward [phase] from where everything
  /// is now, the card going at [velocity] (points per second, down).
  void _go(TransitionPhase phase, {double velocity = 0}) {
    final from = [for (var i = 0; i < snapshot.count; i++) progress(i)];
    final fromRect = pickedRect;
    _held = null;
    _drag = 0;
    _from = from;
    _fromRect = fromRect;
    _setPhase(phase);
    final way = _toRect.top - fromRect.top;
    _velocity = way.abs() < 1 ? 0 : (velocity / way).clamp(-20.0, 20.0);
    _ms = 0;
    _lastTop = double.nan;
    _start = null;
    _ticker
      ..stop()
      ..start();
    notifyListeners();
  }

  /// Starts closing, from where everything is now: the card from where it
  /// is on screen (the details scrolled or pulled down). Without the card
  /// (deleted) it is done at once.
  void close({double velocity = 0}) {
    if (_phase == TransitionPhase.closing && !held) return;
    final card = cardKey.currentContext?.findRenderObject();
    if (card is! RenderBox || !card.attached || !card.hasSize) {
      return dismiss();
    }
    ScrollPosition? scroll;
    var scrolled = 0.0;
    if (_phase == TransitionPhase.open) {
      _detailsCard = MatrixUtils.transformRect(
        card.getTransformTo(null),
        Offset.zero & card.size,
      );
      scroll = Scrollable.maybeOf(cardKey.currentContext!)?.position;
      if (scroll != null && scroll.hasPixels) {
        scrolled = scroll.pixels - scroll.minScrollExtent;
      }
    }
    // From where the card is on screen.
    _go(TransitionPhase.closing, velocity: velocity);
    if (scrolled > 0) {
      // Scrolled down, the details cut off the card where it leaves the
      // screen: it would land in the stack cut. Back at the top, the whole
      // card is there; the card is drawn from there, so nothing on screen
      // moves.
      scroll!.jumpTo(scroll.minScrollExtent);
      _detailsCard = _detailsCard.translate(0, scrolled);
    }
  }

  /// A finger takes hold while it moves: everything stops where it is.
  void grab() {
    if (_phase == TransitionPhase.open || held) return;
    final now = [for (var i = 0; i < snapshot.count; i++) progress(i)];
    _heldRect = pickedRect;
    _held = now;
    _drag = 0;
    _ticker.stop();
    notifyListeners();
  }

  /// Held while opening, and the finger pushes up: it is open from now on,
  /// so the details can scroll with that finger. Only when the card is
  /// nearly at its place in the details (it goes the rest at once, a few
  /// points); further away, or pulled down first, the card stays held.
  bool handOver() {
    if (_phase != TransitionPhase.opening || !held || _drag > 0) return false;
    final a = _heldRect, b = _detailsCard;
    if ((a.top - b.top).abs() > _handOverPoints ||
        (a.width - b.width).abs() > _handOverPoints) {
      return false;
    }
    _held = null;
    _drag = 0;
    _ticker.stop();
    _setPhase(TransitionPhase.open);
    notifyListeners();
    return true;
  }

  /// How near the card must be for [handOver]: a tenth of its way, about
  /// 150 ms after the tap.
  static const double _handOverPoints = 48;

  /// The finger moved [dy] down (up when negative).
  void drag(double dy) {
    if (!held) return;
    _drag += dy;
    notifyListeners();
  }

  /// The finger let go, going [velocity] points per second down: a flick
  /// or a pull far enough down closes, a flick up opens; otherwise it goes
  /// on the way it went.
  void letGo(double velocity) {
    if (!held) return;
    final wasClosing = _phase == TransitionPhase.closing;
    final closes = velocity > 400
        ? true
        : velocity < -400
        ? false
        : _drag > 60
        ? true
        : _drag < -30
        ? false
        : wasClosing;
    if (closes) return _go(TransitionPhase.closing, velocity: velocity);
    _staggered = false;
    _go(TransitionPhase.opening, velocity: velocity);
  }

  /// Ends it at once, without the way back (the card was deleted).
  void dismiss() => _finish();

  bool _finished = false;

  void _finish() {
    if (_finished) return;
    _finished = true;
    _ticker.stop();
    _onDone();
  }

  @override
  void dispose() {
    _list?.removeListener(notifyListeners);
    _ticker.dispose();
    phaseListenable.dispose();
    super.dispose();
  }
}

/// Above the app's navigator: makes one [CardTransition] at a time and
/// gives it to whatever draws or follows it ([CardTransitionScope]).
class CardTransitions extends StatefulWidget {
  final Widget child;

  const CardTransitions({super.key, required this.child});

  @override
  State<CardTransitions> createState() => CardTransitionsState();
}

class CardTransitionsState extends State<CardTransitions>
    with TickerProviderStateMixin {
  final current = ValueNotifier<CardTransition?>(null);

  /// Whether a card is opening, open or closing: then another tap on a card
  /// does nothing.
  bool get busy => current.value != null;

  /// Closes the open card (the back button); false when none is open.
  bool closeOpen() {
    final t = current.value;
    if (t == null) return false;
    t.close();
    return true;
  }

  /// Opens a card from the stack, with its [details]; false when one is
  /// already busy.
  bool open({
    required TransitionSnapshot snapshot,
    required Widget Function(BuildContext context, CardTransition transition)
    details,
    ScrollPosition? list,
  }) {
    if (busy) return false;
    late final CardTransition transition;
    transition = CardTransition(
      choreography: Choreography(snapshot, CardMotion.current.value),
      details: details,
      vsync: this,
      list: list,
      onDone: () {
        if (current.value == transition) current.value = null;
        transition.dispose();
      },
    );
    current.value = transition;
    return true;
  }

  @override
  void dispose() {
    current.value?.dispose();
    current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CardTransitionScope(state: this, child: widget.child);
}

class CardTransitionScope extends InheritedWidget {
  final CardTransitionsState state;

  const CardTransitionScope({
    super.key,
    required this.state,
    required super.child,
  });

  static CardTransitionsState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CardTransitionScope>()?.state;

  @override
  bool updateShouldNotify(CardTransitionScope oldWidget) =>
      oldWidget.state != state;
}

/// Builds with the running transition (null when none) on every frame of
/// it.
class CardTransitionBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, CardTransition? transition)
  builder;

  const CardTransitionBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final scope = CardTransitionScope.maybeOf(context);
    if (scope == null) return builder(context, null);
    return ValueListenableBuilder<CardTransition?>(
      valueListenable: scope.current,
      builder: (context, transition, _) => transition == null
          ? builder(context, null)
          : ListenableBuilder(
              listenable: transition,
              builder: (context, _) => builder(context, transition),
            ),
    );
  }
}
