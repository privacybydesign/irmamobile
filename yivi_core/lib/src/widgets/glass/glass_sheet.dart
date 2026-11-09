import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/laid_out_box.dart";
import "../irma_app_bar.dart";
import "../irma_close_button.dart";
import "../pull_to_dismiss_physics.dart";
import "../scroll_edge.dart";
import "glass_surface.dart";
import "sheet_actions.dart";
import "sheet_layout.dart";

part "glass_sheet_header.dart";
part "glass_sheet_pages.dart";
part "glass_sheet_page.dart";

/// Shows [builder]'s content in the app's one sheet: a full-width sheet
/// attached to the bottom of the screen, as tall as a native iOS sheet (its
/// top at the top of the safe area, where the Data tab's search field
/// starts), that closes on a tap outside it or a drag down. It is a page
/// route, so a [Hero] can fly into it. On tablets ([useFormSheet]) it is a
/// form sheet in the middle, 540 wide.
///
/// To ask before it closes (for example while something is under way in it),
/// wrap the content in a [GlassSheetConfirmDismiss].
///
/// The sheet adds no padding of its own: the content starts with a
/// [GlassSheetHeader] (or is a [GlassSheetPage]) and pads its body 16 from
/// the sides. Its bottom padding, clear of the home indicator, is in
/// `MediaQuery.paddingOf(context).bottom`, so a list can scroll under the
/// bottom edge.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  SheetMotion motion = SheetMotion.standard,
}) {
  if (useFormSheet(context)) {
    // A page route, as on the phone, so heroes fly into the sheet (they
    // don't into a dialog's popup route).
    return Navigator.of(context, rootNavigator: true).push(
      _GlassFormSheetRoute<T>(
        builder: builder,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );
  }
  return Navigator.of(context).push(
    _GlassSheetRoute<T>(
      builder: builder,
      motion: motion,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

/// How a phone sheet slides up and down: how long, on which curve, and how
/// long it waits first (a card that is picked up before the sheet comes in
/// under it; a card that lands while the sheet goes).
class SheetMotion {
  final Duration open;
  final Duration close;
  final Curve openCurve;
  final Curve closeCurve;
  final Duration openDelay;
  final Duration closeDelay;

  const SheetMotion({
    required this.open,
    required this.close,
    this.openCurve = Curves.easeOutCubic,
    this.closeCurve = Curves.easeInCubic,
    this.openDelay = Duration.zero,
    this.closeDelay = Duration.zero,
  });

  /// Every other sheet.
  static const standard = SheetMotion(
    open: Duration(milliseconds: 420),
    close: Duration(milliseconds: 320),
  );

  /// A sheet over the share screen (Welk kaartje deel je?, the trust sheet,
  /// the message): it goes down a beat after it is told to.
  static const share = SheetMotion(
    open: Duration(milliseconds: 380),
    close: Duration(milliseconds: 320),
    openCurve: YiviMotion.ease,
    closeCurve: YiviMotion.leave,
    closeDelay: Duration(milliseconds: 120),
  );

  /// The sheet a card is added in.
  static const issue = SheetMotion(
    open: Duration(milliseconds: 420),
    close: Duration(milliseconds: 360),
    openCurve: YiviMotion.ease,
    closeCurve: YiviMotion.leave,
  );

  SheetMotion copyWith({Duration? openDelay, Duration? closeDelay}) =>
      SheetMotion(
        open: open,
        close: close,
        openCurve: openCurve,
        closeCurve: closeCurve,
        openDelay: openDelay ?? this.openDelay,
        closeDelay: closeDelay ?? this.closeDelay,
      );
}

/// Makes the sheet at [context] wait [delay] before it goes down, the next
/// time it closes: a card is picked up first and lands while it goes.
void delayGlassSheetClose(BuildContext context, Duration delay) {
  final route = ModalRoute.of(context);
  if (route is _GlassSheetRoute) {
    route.motion = route.motion.copyWith(closeDelay: delay);
  }
}

/// The box of [key], in a sheet, in [overlay]'s coordinates as it will be
/// once the sheet is all the way up: where it is now, without the sheet's
/// slide in. For a flight that waits there while the sheet comes in under
/// it.
Rect? sheetSettledBox(GlobalKey key, RenderBox overlay) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !overlay.attached) return null;
  // The route's slide is the outermost translation above the box.
  RenderFractionalTranslation? slide;
  for (var node = box.parent; node != null; node = node.parent) {
    if (node == overlay) break;
    if (node is RenderFractionalTranslation) slide = node;
  }
  final Offset at;
  if (slide == null) {
    at = box.localToGlobal(Offset.zero, ancestor: overlay);
  } else {
    final page = slide.child!;
    at =
        slide.localToGlobal(Offset.zero, ancestor: overlay) +
        box.localToGlobal(Offset.zero, ancestor: page);
  }
  return at & box.size;
}

/// The width of a sheet on a tablet (a form sheet in the middle): 540, as
/// an iOS form sheet, or less in a narrow window. One column: under
/// [sheetColumnsWidth].
double tabletSheetWidth(double window) => math.min(540.0, window - 48);

/// The height of a sheet on a tablet: at most 85% of the window, and no
/// taller than 720 (a native form sheet's proportions; the QR scanner's).
double tabletSheetHeight(double window) => math.min(window * 0.85, 720.0);

/// The dim over the page under a sheet: the phone's sheet and every form
/// sheet on a tablet.
const sheetDim = Color(0x470C1824);

/// How a form sheet on a tablet comes in (and goes) on [curved]: it rises a
/// little and settles while it fades in. The dim fades on its own.
Widget formSheetTransition(Animation<double> curved, Widget child) =>
    FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 48 * (1 - curved.value)),
          child: Transform.scale(
            scale: 0.97 + 0.03 * curved.value,
            child: child,
          ),
        ),
      ),
    );

/// The easing of [formSheetTransition].
CurvedAnimation formSheetCurve(Animation<double> animation) => CurvedAnimation(
  parent: animation,
  curve: YiviMotion.ease,
  reverseCurve: Curves.easeIn,
);

/// The scroll physics for a list in a sheet (see [GlassSheetScope]).
ScrollPhysics? glassSheetScrollPhysics(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<GlassSheetScope>()?.physics;

/// Hands a sheet's content the physics for its list: as on the credential's
/// page and in native iOS sheets, a drag that starts at the top of the list
/// pulls the sheet down with it, and far enough or fast enough closes it; a
/// drag that starts further down only scrolls.
class GlassSheetScope extends InheritedWidget {
  final ScrollPhysics physics;

  const GlassSheetScope({
    super.key,
    required this.physics,
    required super.child,
  });

  @override
  bool updateShouldNotify(GlassSheetScope oldWidget) =>
      physics != oldWidget.physics;
}

/// The sheet on a tablet: a form sheet in the middle of the window, over a
/// dim barrier, closing on a tap outside it. A [PageRoute], so heroes fly
/// into it as into the phone's sheet ([_GlassSheetRoute]).
class _GlassFormSheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  _GlassFormSheetRoute({required this.builder, required this.barrierLabel});

  @override
  final String? barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => sheetDim;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  /// Made once: a new one each frame would add a listener every time.
  late final CurvedAnimation _curved = formSheetCurve(animation!);

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _formSheet(context, builder);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => formSheetTransition(_curved, child);
}

/// The form sheet of [_GlassFormSheetRoute], placed in the window.
Widget _formSheet(BuildContext context, WidgetBuilder builder) {
  final media = MediaQuery.of(context);
  final screen = media.size.height;
  // Every sheet as tall as a form sheet may be.
  final height = tabletSheetHeight(screen);
  final keyboard = media.viewInsets.bottom;
  // Centred; with the keyboard up it moves up, as a native form sheet,
  // centred in the room above the keyboard but no higher than 12
  // below the safe area. What still falls behind the keyboard, the
  // content ends above (as in the phone's sheet), so its buttons
  // stay in sight.
  final lowest = (screen - height) / 2;
  final top = ((screen - keyboard - height) / 2)
      .clamp(math.min(media.padding.top + 12, lowest), lowest)
      .toDouble();
  final covered = math.max(0.0, top + height - (screen - keyboard));
  return MediaQuery.removeViewInsets(
    context: context,
    removeBottom: true,
    // In the safe area: clear of a side panel (an unfolded phone
    // held sideways) or a notch.
    child: Padding(
      padding: EdgeInsets.only(
        top: top,
        left: 24 + media.padding.left,
        right: 24 + media.padding.right,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tabletSheetWidth(
              media.size.width - media.padding.left - media.padding.right,
            ),
            maxHeight: height,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: _FormSheetDrag(
              child: _GlassSheet(
                attached: false,
                height: height,
                keyboard: covered,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A drag down on a form sheet's header moves it down with the finger; far
/// enough or fast enough it closes (through [Navigator.maybePop], so a
/// [GlassSheetConfirmDismiss] asks first), else it springs back. As a
/// native iPad form sheet.
class _FormSheetDrag extends StatefulWidget {
  final Widget child;

  const _FormSheetDrag({required this.child});

  @override
  State<_FormSheetDrag> createState() => _FormSheetDragState();
}

class _FormSheetDragState extends State<_FormSheetDrag>
    with SingleTickerProviderStateMixin {
  late final _offset = AnimationController.unbounded(vsync: this);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _back() => _offset.animateTo(
    0,
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) => GestureDetector(
    // Kept out of the semantics tree, as the phone sheet's drag.
    excludeFromSemantics: true,
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: (d) =>
        _offset.value = math.max(0, _offset.value + (d.primaryDelta ?? 0)),
    onVerticalDragEnd: (d) {
      final close = PullToDismissPhysics.shouldDismiss(
        _offset.value,
        d.velocity.pixelsPerSecond.dy,
      );
      _back();
      if (close) closeGlassSheet(context);
    },
    onVerticalDragCancel: _back,
    child: AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: widget.child,
    ),
  );
}

/// Closes the sheet [context] is in: at once, or, while something in it does
/// not let it go ([GlassSheetConfirmDismiss]), by asking that first. A
/// close, not a step back: a [NavigatorPopHandler] in the sheet (a flow
/// with screens of its own, that steps back on the system back) sees
/// [glassSheetClosing] and leaves its screens as they are.
void closeGlassSheet(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route is _GlassSheetRoute) {
    route._close();
  } else {
    Navigator.of(context).maybePop();
  }
}

/// Whether the pop that a [PopScope] or [NavigatorPopHandler] at [context]
/// is told about is the sheet being closed, rather than the system back.
bool glassSheetClosing(BuildContext context) {
  final route = ModalRoute.of(context);
  return route is _GlassSheetRoute && route._closeAsked;
}

/// The route of a sheet: it slides up from the bottom over a dim barrier,
/// closes on a tap outside it, a drag down or a pull of its list, and is a
/// [PageRoute], so heroes fly into it (a modal bottom sheet is not).
class _GlassSheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  /// How it slides; its close delay can change while it is open
  /// ([delayGlassSheetClose]).
  SheetMotion motion;

  _GlassSheetRoute({
    required this.builder,
    required this.barrierLabel,
    this.motion = SheetMotion.standard,
  }) {
    _pull.addListener(_followPull);
  }

  // How far the list is pulled down at its top.
  final _pull = ValueNotifier<double>(0);
  bool _dragStartedAtTop = false;
  bool _pulling = false;
  double _sheetHeight = 1;

  late final _physics = PullToDismissPhysics(
    pull: _pull,
    canPull: () =>
        _dragStartedAtTop &&
        !_held &&
        animation?.status != AnimationStatus.reverse,
    onRelease: _onPullReleased,
  );

  /// While something important happens in the sheet (a [PopScope] in it does
  /// not let it close, see [GlassSheetConfirmDismiss]), a pull of its list
  /// does not move the sheet: the list just scrolls. A drag on its header
  /// still moves it, and letting go to close asks first, as a tap outside
  /// and the system back do (the issuance pages have no close button: the
  /// header is how they are left).
  bool get _held => popDisposition == RoutePopDisposition.doNotPop;

  /// The pop scopes in the sheet are being told about a close (see
  /// [glassSheetClosing]).
  bool _closeAsked = false;

  /// Closes the sheet, or asks the scope that holds it first.
  void _close() {
    if (popDisposition == RoutePopDisposition.doNotPop) {
      _askToClose();
    } else {
      navigator?.pop();
    }
  }

  void _askToClose() {
    _closeAsked = true;
    try {
      onPopInvokedWithResult(false, null);
    } finally {
      _closeAsked = false;
    }
  }

  /// A drag on the sheet's header is moving it.
  bool _dragging = false;

  // From the start of a drag or pull until the sheet has settled after it:
  // the sheet then follows the finger one to one, without its curve.
  //
  // Every start must be ended exactly once. While a navigator has a user
  // gesture in progress, all its routes ignore touches and heroes wait for
  // the gesture to end, so a gesture left open freezes the app (and leaves
  // the card that flies back without its "Change" pill).
  bool _gesture = false;
  NavigatorState? _gestureNavigator;

  void _startGesture() {
    if (_gesture) return;
    _gesture = true;
    _gestureNavigator = navigator;
    _gestureNavigator!.didStartUserGesture();
  }

  void _stopGesture() {
    if (!_gesture) return;
    _gesture = false;
    _gestureNavigator?.didStopUserGesture();
    _gestureNavigator = null;
  }

  /// Closes the sheet, or springs it back open, and ends the gesture once it
  /// has settled, so the curve does not take over half way.
  ///
  /// A close that a [PopScope] in the sheet does not allow (see
  /// [GlassSheetConfirmDismiss]) springs back and is handed to that scope
  /// instead, as a tap outside the sheet or the system back is.
  void _settle({required bool close}) {
    final vetoed = close && popDisposition == RoutePopDisposition.doNotPop;
    var settled = false;
    void done(AnimationStatus status) {
      if (settled || status.isAnimating) return;
      settled = true;
      controller?.removeStatusListener(done);
      _stopGesture();
      // Asks once the sheet is back and the gesture has ended: while a
      // gesture is open the navigator ignores touches, so a dialog could not
      // be tapped.
      if (vetoed) _askToClose();
    }

    controller!.addStatusListener(done);
    if (close && !vetoed) {
      navigator!.pop();
    } else {
      controller!.forward();
    }
    if (!controller!.isAnimating) done(controller!.status);
  }

  void _followPull() {
    if (_pull.value <= 0) {
      // Pulled back up past where it started: the list scrolls again, and
      // the sheet is back in place.
      if (_pulling) {
        _pulling = false;
        controller!.value = 1;
        _stopGesture();
      }
      return;
    }
    if (!_pulling) {
      _pulling = true;
      _startGesture();
    }
    controller!.value = 1 - _pull.value / _sheetHeight;
  }

  void _onPullReleased(double velocity) {
    final pulled = _pull.value;
    // Before the reset, which would otherwise read as a pull taken back.
    _pulling = false;
    _pull.value = 0;
    // A downward flick has a negative scroll velocity.
    _settle(close: PullToDismissPhysics.shouldDismiss(pulled, -velocity));
  }

  bool _onScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      final m = notification.metrics;
      _dragStartedAtTop = m.pixels <= m.minScrollExtent + 0.5;
    }
    return false;
  }

  @override
  void dispose() {
    // Closed in the middle of a gesture (e.g. by the session ending).
    _stopGesture();
    controller?.removeStatusListener(_onCoverStatus);
    _cover(false);
    _pull.dispose();
    _backdrop.dispose();
    super.dispose();
  }

  @override
  final String barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  /// The dim over the page under a sheet.
  static const barrier = sheetDim;

  /// This sheet is fully open: the page under it is covered (GlassSheetCover).
  bool _covering = false;

  /// The sheet is lower than full height ([GlassSheetPage.fit]): the page
  /// above it shows, so it is never covered.
  bool _fitted = false;

  void _setFitted(bool fitted) {
    if (fitted == _fitted) return;
    _fitted = fitted;
    _cover(controller?.status == AnimationStatus.completed && !fitted);
  }

  /// While fully open the sheet hides the route under it: that page, which
  /// shows only as the dimmed strip above the sheet, stays built and laid
  /// out but is not drawn ([ModalRoute.offstage]), and the sheet paints the
  /// strip itself ([_backdrop]). Drawn, the page cost a third of every frame
  /// on a mid-range Android phone. It is back as soon as the sheet moves.
  final _backdrop = ValueNotifier<bool>(false);

  /// The route under this sheet.
  ModalRoute<dynamic>? _below;

  void _cover(bool covering) {
    if (covering == _covering) return;
    _covering = covering;
    GlassSheetCover.covering.value += covering ? 1 : -1;
    _backdrop.value = covering;
    _below?.offstage = covering;
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    if (_covering) _below?.offstage = false;
    _below = previousRoute is ModalRoute ? previousRoute : null;
    if (_covering) _below?.offstage = true;
  }

  void _onCoverStatus(AnimationStatus status) =>
      _cover(status == AnimationStatus.completed && !_fitted);

  @override
  void install() {
    super.install();
    // The controller, not [animation]: on the first frame of the push the
    // hero controller puts this route offstage to measure it, and offstage
    // its [animation] reads as completed. Taken for fully open, that hid the
    // page under the sheet as well, and the screen was black for a frame.
    controller!.addStatusListener(_onCoverStatus);
  }

  @override
  Color get barrierColor => barrier;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => motion.openDelay + motion.open;

  @override
  Duration get reverseTransitionDuration => motion.closeDelay + motion.close;

  /// How far up the sheet is at route animation [t]: the wait comes first,
  /// then the slide on its curve.
  double _shown(double t, bool closing) {
    final delay = closing ? motion.closeDelay : motion.openDelay;
    final run = closing ? motion.close : motion.open;
    final total = (delay + run).inMicroseconds;
    if (total == 0) return t;
    // Elapsed of the way being gone: from 0 (closed) when opening, from 1
    // (open) when closing.
    final elapsed = (closing ? 1 - t : t) * total;
    final local = ((elapsed - delay.inMicroseconds) / run.inMicroseconds).clamp(
      0.0,
      1.0,
    );
    final eased = (closing ? motion.closeCurve : motion.openCurve).transform(
      local,
    );
    return closing ? 1 - eased : eased;
  }

  /// The sheet's height, as last laid out. A scroll can start during layout
  /// (a lazy list that grows as rows are built), when the size may not be
  /// read; the last known height stands in then.
  double _measure(BuildContext context) {
    final box = context.findRenderObject();
    final layingOut =
        SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks;
    if (!layingOut && box is RenderBox && box.hasSize) {
      _sheetHeight = box.size.height;
    }
    return _sheetHeight;
  }

  /// Follows a drag of [delta] logical pixels on a sheet [height] tall.
  void _drag(double delta, double height) {
    controller!.value -= delta / height;
  }

  /// Ends a drag: closes on a fling down or past half way, else springs back.
  void _release(double velocity) => _settle(
    close:
        velocity > PullToDismissPhysics.dismissVelocity ||
        (velocity >= 0 && controller!.value < 0.5),
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final screen = media.size.height;
    final landscape = usePhoneLandscape(context);
    // As a native iOS sheet: from the top of the safe area to the bottom
    // (measured on iOS 27: the top edge at the top inset, 62 pt on an
    // iPhone 17 Pro). On a phone held sideways there is no top inset: 10
    // below the top; the sheet goes from edge to edge, its content between
    // the safe areas left and right.
    final height = (screen - (landscape ? 10 : media.padding.top)).clamp(
      0.0,
      screen,
    );
    final sides = landscape
        ? EdgeInsets.only(left: media.padding.left, right: media.padding.right)
        : EdgeInsets.zero;
    // The sheet keeps its place and size when the keyboard comes up: only
    // its content ends above the keyboard (see _GlassSheet).
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Align(
          alignment: Alignment.bottomCenter,
          // At most this high: a sheet that fits its content is lower.
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: Material(
              type: MaterialType.transparency,
              child: LayoutBuilder(
                builder: (context, _) => GestureDetector(
                  // Dragging the sheet outside its list (its header). Kept out
                  // of the semantics tree: as a scroll action it hid the whole
                  // sheet (title, close button, content) from screen readers.
                  // They close it with the close button or the barrier.
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) {
                    _dragging = true;
                    _startGesture();
                  },
                  onVerticalDragUpdate: (d) {
                    if (_dragging) {
                      _drag(d.primaryDelta ?? 0, _measure(context));
                    }
                  },
                  onVerticalDragEnd: (d) {
                    if (!_dragging) return;
                    _dragging = false;
                    _release(d.velocity.pixelsPerSecond.dy);
                  },
                  // Interrupted by the system: back in place.
                  onVerticalDragCancel: () {
                    if (!_dragging) return;
                    _dragging = false;
                    if (_gesture && !_pulling) _release(0);
                  },
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (n) {
                      _measure(context);
                      return _onScrollStart(n);
                    },
                    child: GlassSheetScope(
                      physics: _physics,
                      child: _GlassSheet(
                        attached: true,
                        height: height,
                        onFitted: _setFitted,
                        keyboard: media.viewInsets.bottom,
                        bottomInset: media.viewInsets.bottom > 0
                            ? 0
                            : media.padding.bottom,
                        sides: sides,
                        child: builder(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final sheet = AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        final shown = _gesture
            ? t
            : MediaQuery.disableAnimationsOf(context)
            ? (t > 0 ? 1.0 : 0.0)
            : _shown(t, animation.status == AnimationStatus.reverse);
        return FractionalTranslation(
          translation: Offset(0, 1 - shown),
          child: child,
        );
      },
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // The dimmed page as it looked around the sheet, flat, while the
        // page itself is not drawn; a tap on it closes the sheet, as one on
        // the barrier does. The sheet stays the Stack's second child either
        // way, so it keeps its state.
        ValueListenableBuilder<bool>(
          valueListenable: _backdrop,
          builder: (context, backdrop, _) => !backdrop
              ? const SizedBox.shrink()
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: _close,
                  child: ColoredBox(
                    color: Color.alphaBlend(
                      barrier,
                      YiviPalette.of(context).background,
                    ),
                  ),
                ),
        ),
        sheet,
      ],
    );
  }
}

/// The look of every sheet: solid, corners of 38 (concentric with a
/// 44 close button inset 16). Attached to the bottom edge it has square
/// bottom corners, which the screen's own corners round off.
class _GlassSheet extends StatefulWidget {
  final bool attached;

  /// Its full height; lower while a page fits its content.
  final double height;
  // Room for the home indicator, handed to the content as its bottom padding.
  final double bottomInset;

  /// The keyboard's height: the content (its scroll view and pinned buttons)
  /// ends above it, the sheet itself does not move or grow.
  final double keyboard;
  final Widget child;

  /// Held sideways: the safe areas left and right, between which the
  /// content lies (the sheet itself goes from edge to edge).
  final EdgeInsets sides;

  /// Told whether the sheet is lower than [height] (or on its way there), so
  /// the route leaves the page above it uncovered.
  final ValueChanged<bool>? onFitted;

  const _GlassSheet({
    required this.attached,
    required this.height,
    this.bottomInset = 0,
    this.keyboard = 0,
    this.sides = EdgeInsets.zero,
    this.onFitted,
    required this.child,
  });

  static const _radius = Radius.circular(YiviCorners.sheet);

  @override
  State<_GlassSheet> createState() => _GlassSheetState();
}

class _GlassSheetState extends State<_GlassSheet>
    with SingleTickerProviderStateMixin {
  /// The height a page that fits its content asks for ([GlassSheetPage.fit]);
  /// null: full height.
  double? _fit;

  /// No page has said yet how high it wants the sheet: the first answer
  /// is taken at once, while the sheet is still coming up.
  bool _first = true;

  /// The height laid out now, between full and fitted while it changes.
  late final _height = AnimationController.unbounded(vsync: this);

  /// The height of the frame the last report was measured in.
  double _laidOut = 0;

  @override
  void dispose() {
    _height.dispose();
    super.dispose();
  }

  /// A page's report: [slack] is how much room its content leaves (negative
  /// when it scrolls), null when it wants the full height.
  void _report(double? slack) {
    if (!mounted) return;
    final full = widget.height;
    double? fit;
    if (slack != null) {
      final wanted = _laidOut - slack;
      // Nearly full: just full.
      fit = wanted >= full - 24 ? null : wanted;
    }
    if (fit == _fit && !_first) return;
    if (fit != null && _fit != null && (fit - _fit!).abs() < 0.5) return;
    final wasFirst = _first;
    _first = false;
    _fit = fit;
    final target = fit ?? full;
    if (fit != null) widget.onFitted?.call(true);
    if (wasFirst || MediaQuery.disableAnimationsOf(context)) {
      _height.value = target;
      if (fit == null) widget.onFitted?.call(false);
      setState(() {});
      return;
    }
    // Grows into the full sheet while the next page slides in (or back to
    // the fitted one as it slides out), as a low sheet grows into the one a
    // card is added in.
    _height
        .animateTo(
          target,
          duration: const Duration(milliseconds: 450),
          curve: YiviMotion.ease,
        )
        .whenCompleteOrCancel(() {
          if (mounted && _fit == null) widget.onFitted?.call(false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final attached = widget.attached;
    final full = widget.height;
    if (_first || (_fit == null && !_height.isAnimating)) {
      _height.value = _fit ?? full;
    }
    final keyboard = widget.keyboard;
    final bottomInset = widget.bottomInset;
    final palette = YiviPalette.of(context);
    final radius = attached
        ? const BorderRadius.vertical(top: _GlassSheet._radius)
        : const BorderRadius.all(_GlassSheet._radius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final media = MediaQuery.of(context);
    // Solid, at the sheet level: in light the page colour, so its white cards stand out without a shadow; in dark below
    // the raised cards in it ([YiviPaletteScope]).
    final fill = palette.sheet;
    return GlassSurface(
      key: const Key("glass_sheet"),
      fill: fill,
      shape: shape,
      // Its content lays out by the sheet's width, not the screen's
      // (useSheetColumns).
      child: LayoutBuilder(
        builder: (context, constraints) => SheetWidthScope(
          width: constraints.maxWidth - widget.sides.horizontal,
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: _SheetHeight(
              height: _height,
              onLaidOut: (h) => _laidOut = h,
              child: Padding(
                padding: widget.sides.copyWith(bottom: keyboard),
                child: MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(
                      top: 0,
                      bottom: 20 + bottomInset,
                      // In landscape the sheet sits between the side insets.
                      left: 0,
                      right: 0,
                    ),
                    // The device's inset where the sheet meets the bottom edge,
                    // so a button lands where it does on a full screen.
                    viewPadding: media.viewPadding.copyWith(
                      top: 0,
                      bottom: attached ? media.viewPadding.bottom : 0,
                    ),
                  ),
                  // Its bar has text buttons when it floats.
                  child: _GlassSheetFloating(
                    floating: !attached,
                    child: _SheetFit(
                      report: _report,
                      // Cards on the sheet one level above it.
                      child: YiviPaletteScope.onSheet(child: widget.child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's height while it changes between fitting its content and
/// full. Tells [onLaidOut] the height of every layout.
class _SheetHeight extends StatelessWidget {
  final Animation<double> height;
  final ValueChanged<double> onLaidOut;
  final Widget child;

  const _SheetHeight({
    required this.height,
    required this.onLaidOut,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: height,
      child: child,
      builder: (context, child) {
        onLaidOut(height.value);
        return SizedBox(height: height.value, child: child);
      },
    );
  }
}

/// Where a page of a sheet tells it how high it wants to be: see
/// [GlassSheetPage.fit].
class _SheetFit extends InheritedWidget {
  final ValueChanged<double?> report;

  const _SheetFit({required this.report, required super.child});

  static ValueChanged<double?>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetFit>()?.report;

  @override
  bool updateShouldNotify(_SheetFit old) => old.report != report;
}

/// Tells a [GlassSheetScrollView] in a page that fits its content to measure
/// it ([GlassSheetPage.fit]); only on the page on top.
class _FitPage extends InheritedWidget {
  final ValueChanged<double?> report;

  const _FitPage({required this.report, required super.child});

  static _FitPage? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FitPage>();

  @override
  bool updateShouldNotify(_FitPage old) => old.report != report;
}

/// Whether the sheet around [context] floats in the middle of the window
/// (a tablet's form sheet) rather than being attached to the bottom edge.
/// Its bar then has text buttons, as a native iPad form sheet: "Cancel" or
/// "‹ Back" at the left, the way on at the right, no close button.
class _GlassSheetFloating extends InheritedWidget {
  final bool floating;

  const _GlassSheetFloating({required this.floating, required super.child});

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_GlassSheetFloating>()
          ?.floating ??
      false;

  @override
  bool updateShouldNotify(_GlassSheetFloating old) => old.floating != floating;
}

/// Whether a sheet page shows its way on ([SheetAction]) in its bar: on a
/// tablet's form sheet and in a wide sheet (a phone held sideways), where
/// the keyboard would cover a button at the bottom. A phone held upright has
/// it at the bottom, in the thumb's reach, right above the keyboard.
bool sheetActionInBar(BuildContext context) =>
    _GlassSheetFloating.of(context) || useSheetColumns(context);

/// What a sideways [GlassSheetPage] puts at the bottom of its
/// [SheetSplit]'s left column: its [GlassSheetPage.bottom], when it is not
/// in the bar.
class SheetSplitBottom extends InheritedWidget {
  final Widget bottom;

  const SheetSplitBottom({
    super.key,
    required this.bottom,
    required super.child,
  });

  static Widget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetSplitBottom>()?.bottom;

  @override
  bool updateShouldNotify(SheetSplitBottom old) => old.bottom != bottom;
}

/// Every page under it has the close button at the right of the bar on a
/// phone held upright, also the pages that are otherwise left by back or a
/// drag down (adding a card: there the way on is at the bottom, so the
/// right of the bar is free). Held sideways and on a tablet the pages keep
/// their own buttons, as the way on is in the bar there.
class SheetKeepsClose extends InheritedWidget {
  const SheetKeepsClose({super.key, required super.child});

  /// Whether [context] is in the pages of adding a card (sideways their way
  /// on takes the close button's place).
  static bool inScope(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetKeepsClose>() != null;

  /// Whether the pages at [context] show the close button at the right.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetKeepsClose>() != null &&
      !sheetActionInBar(context);

  @override
  bool updateShouldNotify(SheetKeepsClose oldWidget) => false;
}

/// Asks before the sheet around it closes, while [ask] is true: a tap outside
/// the sheet, its close button or the system back then runs [confirm]
/// instead, and the sheet closes only when that returns true. A drag or pull
/// down does not move the sheet then; its list just scrolls. While [ask] is
/// false the sheet closes as usual.
class GlassSheetConfirmDismiss extends StatelessWidget {
  final bool ask;
  final Future<bool> Function() confirm;
  final Widget child;

  const GlassSheetConfirmDismiss({
    super.key,
    required this.ask,
    required this.confirm,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !ask,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final navigator = Navigator.of(context);
      if (await confirm() && navigator.mounted) navigator.pop();
    },
    child: child,
  );
}

/// A page of [GlassSheetPages] with screens of its own (adding a document):
/// while [enabled], a back swipe on the page goes back one of its screens,
/// following the finger, instead of back a page of the sheet.
abstract interface class GlassSheetInnerSwipe {
  /// Whether a swipe that starts now goes back a screen in the page.
  bool get enabled;

  void start();

  /// [delta]: the part of the page's width the finger moved, to the right.
  void update(double delta);

  /// [velocity]: the finger's speed when let go, in points per second, to
  /// the right.
  void end(double velocity);
}

/// [child], hidden while not [visible] but still laid out, animated and
/// holding its state (a page's buttons under the top page's own).
Widget _kept(bool visible, Widget child) => Visibility(
  visible: visible,
  maintainSize: true,
  maintainAnimation: true,
  maintainState: true,
  child: child,
);
