import "dart:math" as math;

import "package:flutter/scheduler.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../irma_app_bar.dart";
import "../irma_close_button.dart";
import "../pull_to_dismiss_physics.dart";
import "glass_surface.dart";
import "scroll_edge.dart";
import "sheet_action_row.dart";

/// Shows [builder]'s content in the app's one sheet: a full-width glass sheet
/// attached to the bottom of the screen, as tall as a native iOS sheet (its
/// top at the top of the safe area, where the Data tab's search field
/// starts), that closes on a tap outside it or a drag down. It is a page route, so a [Hero] can fly into it. On
/// tablets ([useFormSheet]) it is a form sheet in the middle, 540 wide.
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
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

/// The width of a sheet on a tablet (a form sheet in the middle): 540, as
/// an iOS form sheet, or less in a narrow window. One column: under
/// [sheetColumnsWidth].
double tabletSheetWidth(double window) => math.min(540.0, window - 48);

/// The height of a sheet on a tablet: at most 85% of the window, and no
/// taller than 720 (a native form sheet's proportions; the QR scanner's).
double tabletSheetHeight(double window) => math.min(window * 0.85, 720.0);

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
  Color get barrierColor => Colors.black54;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

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
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
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
  );
}

/// The route of a sheet: it slides up from the bottom over a dim barrier,
/// closes on a tap outside it, a drag down or a pull of its list, and is a
/// [PageRoute], so heroes fly into it (a modal bottom sheet is not).
class _GlassSheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  _GlassSheetRoute({required this.builder, required this.barrierLabel}) {
    _pull.addListener(_followPull);
  }

  /// A pull this far, or a flick down this fast, closes the sheet: the
  /// numbers of the credential's page.
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

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
  /// not let it close, see [GlassSheetConfirmDismiss]), a drag or pull down
  /// does not move the sheet at all: its list just scrolls. A tap outside,
  /// the close button and the system back still ask first.
  bool get _held => popDisposition == RoutePopDisposition.doNotPop;

  /// The current drag on the sheet's header moves it (it was not [_held]
  /// when it started).
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
      if (vetoed) onPopInvokedWithResult(false, null);
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
    _settle(close: pulled > _dismissDistance || velocity < -_dismissVelocity);
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
  static const barrier = Color(0x470C1824);

  /// This sheet is fully open: the page under it is covered (GlassSheetCover).
  bool _covering = false;

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
      _cover(status == AnimationStatus.completed);

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
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

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
    close: velocity > 700 || (velocity >= 0 && controller!.value < 0.5),
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
    // below the top, and between the safe areas left and right.
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
        padding: sides,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(height: height),
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
                    _dragging = !_held;
                    if (_dragging) _startGesture();
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
                        keyboard: media.viewInsets.bottom,
                        bottomInset: media.viewInsets.bottom > 0
                            ? 0
                            : media.padding.bottom,
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
            : (animation.status == AnimationStatus.reverse
                      ? Curves.easeInCubic
                      : Curves.easeOutCubic)
                  .transform(t);
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
                  onTap: () => navigator?.maybePop(),
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

/// The look of every sheet: frosted glass, corners of 38 (concentric with a
/// 44 close button inset 16). Attached to the bottom edge it has square
/// bottom corners, which the screen's own corners round off.
class _GlassSheet extends StatefulWidget {
  final bool attached;
  final double? height;
  // Room for the home indicator, handed to the content as its bottom padding.
  final double bottomInset;

  /// The keyboard's height: the content (its scroll view and pinned buttons)
  /// ends above it, the sheet itself does not move or grow.
  final double keyboard;
  final Widget child;

  const _GlassSheet({
    required this.attached,
    required this.height,
    this.bottomInset = 0,
    this.keyboard = 0,
    required this.child,
  });

  static const _radius = Radius.circular(YiviCorners.sheet);

  @override
  State<_GlassSheet> createState() => _GlassSheetState();
}

class _GlassSheetState extends State<_GlassSheet> {
  /// How many [GlassSheetNoRim]s in the sheet hide its rim.
  final _rimHiders = _RimHiders();

  @override
  void dispose() {
    _rimHiders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attached = widget.attached;
    final height = widget.height;
    final keyboard = widget.keyboard;
    final bottomInset = widget.bottomInset;
    final palette = YiviPalette.of(context);
    final radius = attached
        ? const BorderRadius.vertical(top: _GlassSheet._radius)
        : const BorderRadius.all(_GlassSheet._radius);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final media = MediaQuery.of(context);
    // Opaque and not blurred: the glass fill let only a trace of the blurred
    // page through, and that blur, redone every frame over the whole sheet,
    // was the costliest thing on screen. The fill over the dimmed page, as
    // it looked, made solid.
    final fill = Color.alphaBlend(
      palette.glassStrongFill,
      Color.alphaBlend(_GlassSheetRoute.barrier, palette.background),
    );
    return ValueListenableBuilder<int>(
      valueListenable: _rimHiders,
      builder: (context, hiders, child) => GlassSurface(
        key: const Key("glass_sheet"),
        fill: fill,
        blur: false,
        rim: hiders == 0,
        shape: shape,
        child: child!,
      ),
      // Glass on the sheet would only blur its flat colour; the sheet's own
      // scroll edge does blur its content (it is not covered).
      child: _SheetRim(
        hiders: _rimHiders,
        // Its content lays out by the sheet's width, not the screen's
        // (useSheetColumns).
        child: LayoutBuilder(
          builder: (context, constraints) => SheetWidthScope(
            width: constraints.maxWidth,
            child: GlassScope(
              blur: false,
              covered: false,
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: SizedBox(
                  height: height,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: keyboard),
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
                      child: GlassSheetFloating(
                        floating: !attached,
                        child: widget.child,
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
}

/// How many [GlassSheetNoRim]s hide a sheet's rim; knows when the sheet is
/// gone.
class _RimHiders extends ValueNotifier<int> {
  _RimHiders() : super(0);

  bool alive = true;

  @override
  void dispose() {
    alive = false;
    super.dispose();
  }
}

class _SheetRim extends InheritedWidget {
  final _RimHiders hiders;

  const _SheetRim({required this.hiders, required super.child});

  @override
  bool updateShouldNotify(_SheetRim old) => old.hiders != hiders;
}

/// Hides the light rim of the sheet it is in while it is there, for content
/// that fills the sheet edge to edge in a dark colour (the QR scanner's
/// camera), where the rim would show as a white border.
class GlassSheetNoRim extends StatefulWidget {
  final Widget child;

  const GlassSheetNoRim({super.key, required this.child});

  @override
  State<GlassSheetNoRim> createState() => _GlassSheetNoRimState();
}

class _GlassSheetNoRimState extends State<GlassSheetNoRim> {
  _RimHiders? _hiders;

  @override
  void initState() {
    super.initState();
    // After this frame: the sheet is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hiders = context.getInheritedWidgetOfExactType<_SheetRim>()?.hiders;
      _hiders?.value++;
    });
  }

  @override
  void dispose() {
    // After this frame too: while the tree is being torn down the sheet
    // can't rebuild. It may be gone by then.
    final hiders = _hiders;
    if (hiders != null) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (hiders.alive) hiders.value--;
        })
        ..scheduleFrame();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Whether the sheet around [context] floats in the middle of the window
/// (a tablet's form sheet) rather than being attached to the bottom edge.
/// Its bar then has text buttons, as a native iPad form sheet: "Cancel" or
/// "‹ Back" at the left, the way on at the right, no close button.
class GlassSheetFloating extends InheritedWidget {
  final bool floating;

  const GlassSheetFloating({
    super.key,
    required this.floating,
    required super.child,
  });

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GlassSheetFloating>()
          ?.floating ??
      false;

  @override
  bool updateShouldNotify(GlassSheetFloating old) => old.floating != floating;
}

/// Whether a sheet page shows its way on ([SheetAction]) in its bar: on a
/// tablet's form sheet and in a wide sheet (a phone held sideways), where
/// the keyboard would cover a button at the bottom. A phone held upright has
/// it at the bottom, in the thumb's reach, right above the keyboard.
bool sheetActionInBar(BuildContext context) =>
    GlassSheetFloating.of(context) || useSheetColumns(context);

/// The top of a sheet, as the navigation bar of a native iOS sheet: the
/// title in the middle, the ways out at the sides, and in the bar the way
/// on ([action]) where [sheetActionInBar] puts it there.
///
/// - Phone: the round glass back button at the left when [onBack] is set,
///   [action] and the round close button at the right.
/// - Tablet (a floating form sheet): text buttons, as on an iPad: "‹ Back"
///   when [onBack] is set, else "Cancel", at the left; [action] at the
///   right; no close button (a tap outside the sheet closes it).
///
/// Explanatory text goes at the top of the sheet's scrolling content, not
/// here.
class GlassSheetHeader extends StatelessWidget {
  static Duration _switch(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200);

  final String title;

  /// In the title's place while not null (Add data's search field, once the
  /// list has scrolled it away): between the buttons, the title faded out.
  /// On a phone held sideways it stands next to the title instead.
  final Widget? titleWidget;
  final VoidCallback? onBack;

  /// The way on, in the bar at the right (see [sheetActionInBar]).
  final SheetAction? action;

  /// Called instead of [action]'s own callback (a slot's latest one).
  final VoidCallback? onAction;

  /// False on a page that is done ("Success"): no close button, no
  /// "Cancel"; its way on is the way out.
  final bool closable;

  /// The title fades while pages of [GlassSheetPages] change (the bar
  /// itself stays put); null when it simply shows.
  final Animation<double>? titleOpacity;

  /// The back button fades in or out while pages change, when the page it
  /// comes from or goes back to has none; null when it simply shows.
  final Animation<double>? backOpacity;

  /// [action] fades in or out while pages change, when the other page has
  /// none; null when it simply shows.
  final Animation<double>? actionOpacity;

  /// Off for the page under the top one: its buttons sit under the top
  /// page's own.
  final bool buttons;

  /// On a phone held sideways: a second line under the title (who a card is
  /// added for).
  final Widget? subtitle;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.action,
    this.onAction,
    this.closable = true,
    this.titleOpacity,
    this.backOpacity,
    this.actionOpacity,
    this.buttons = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sideways = useSheetColumns(context);
    if (sideways && this.titleWidget != null) return _row(context);
    final palette = YiviPalette.of(context);
    final floating = GlassSheetFloating.of(context);
    final titleWidget = this.titleWidget;
    final subtitle = sideways ? this.subtitle : null;
    final action = sheetActionInBar(context) ? this.action : null;
    final onBack = this.onBack;

    // Names the page (see GlassSheetPages): a screen reader reads it when
    // the page comes in. A new title on the same page (a screen changing
    // below the bar) fades in over the old one.
    final text = Semantics(
      header: true,
      namesRoute: true,
      child: AnimatedSwitcher(
        duration: _switch(context),
        child: KeyedSubtree(
          key: ValueKey(title),
          child: Text(
            title,
            key: const Key("glass_sheet_title"),
            textAlign: TextAlign.center,
            maxLines: sideways ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: palette
                .display(17)
                .copyWith(
                  height: (sideways ? 20 : 22) / 17,
                  color: palette.text,
                ),
          ),
        ),
      ),
    );
    final heading = FadeTransition(
      opacity: titleOpacity ?? kAlwaysCompleteAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            // Gone while a widget takes its place; it still names the page.
            opacity: titleWidget == null ? 1 : 0,
            duration: _switch(context),
            child: subtitle == null
                ? text
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [text, subtitle],
                  ),
          ),
          AnimatedSwitcher(
            duration: _switch(context),
            child: titleWidget == null
                ? const SizedBox.shrink()
                : KeyedSubtree(
                    key: const ValueKey("glass_sheet_title_widget"),
                    child: titleWidget,
                  ),
          ),
        ],
      ),
    );

    Widget shown(Widget child) => Visibility(
      visible: buttons,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: child,
    );
    // maybePop, so a [GlassSheetConfirmDismiss] can ask first.
    void close() => Navigator.of(context).maybePop();
    final Widget? start = floating
        ? (onBack != null || closable
              ? shown(
                  _BarTextButton(
                    key: const Key("glass_sheet_text_back"),
                    label: FlutterI18n.translate(
                      context,
                      onBack != null ? "ui.previous" : "ui.cancel",
                    ),
                    chevron: onBack != null,
                    onTap: onBack ?? close,
                  ),
                )
              : null)
        : (onBack != null
              ? shown(
                  FadeTransition(
                    opacity: backOpacity ?? kAlwaysCompleteAnimation,
                    child: YiviBackButton(onTap: onBack),
                  ),
                )
              : null);
    final end = <Widget>[
      if (action != null)
        Flexible(
          child: shown(
            FadeTransition(
              opacity: actionOpacity ?? kAlwaysCompleteAnimation,
              child: AnimatedSwitcher(
                duration: _switch(context),
                child: SheetBarButton(
                  key: ValueKey((action.label, action.busy, action.enabled)),
                  action: action,
                  onTap: onAction,
                ),
              ),
            ),
          ),
        ),
      if (!floating && closable) shown(IrmaCloseButton(onTap: close)),
    ];
    return Padding(
      // Room under the buttons, also once content scrolls under the bar and
      // its edge shows; less above them on a phone held sideways.
      padding: EdgeInsets.fromLTRB(16, sideways ? 12 : 16, 16, 12),
      child: SizedBox(
        height: 44,
        child: CustomMultiChildLayout(
          delegate: _BarLayout(Directionality.of(context)),
          children: [
            if (start != null) LayoutId(id: _BarSlot.start, child: start),
            LayoutId(id: _BarSlot.title, child: heading),
            if (end.isNotEmpty)
              LayoutId(
                id: _BarSlot.end,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: end,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A phone held sideways with a search field ([titleWidget], Add data's
  /// list): one row, the back button, the title at the start, the search
  /// field next to it, and the close button.
  Widget _row(BuildContext context) {
    final palette = YiviPalette.of(context);
    final titleWidget = this.titleWidget!;
    final subtitle = this.subtitle;
    final text = Semantics(
      header: true,
      namesRoute: true,
      child: Text(
        title,
        key: const Key("glass_sheet_title"),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: palette
            .display(17)
            .copyWith(height: 20 / 17, color: palette.text),
      ),
    );
    final heading = FadeTransition(
      opacity: titleOpacity ?? kAlwaysCompleteAnimation,
      child: subtitle == null
          ? text
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, subtitle],
            ),
    );
    return Padding(
      // As much room under the buttons as above them, for the edge that
      // shows once content scrolls under the bar.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        height: 44,
        child: Row(
          spacing: 12,
          children: [
            if (onBack != null)
              Visibility(
                visible: buttons,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: FadeTransition(
                  opacity: backOpacity ?? kAlwaysCompleteAnimation,
                  child: YiviBackButton(onTap: onBack),
                ),
              ),
            heading,
            Expanded(
              child: FadeTransition(
                opacity: titleOpacity ?? kAlwaysCompleteAnimation,
                child: titleWidget,
              ),
            ),
            if (closable)
              Visibility(
                visible: buttons,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                // maybePop, so a [GlassSheetConfirmDismiss] can ask first.
                child: IrmaCloseButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _BarSlot { start, title, end }

/// The bar's three parts: the buttons at the start and the end as wide as
/// they are, the title in the middle of the bar, kept clear of the wider
/// side on both sides so it stays centred.
class _BarLayout extends MultiChildLayoutDelegate {
  final TextDirection direction;

  _BarLayout(this.direction);

  static const double _gap = 12;

  @override
  void performLayout(Size size) {
    // A long label (the success's "Back to {requestor}") shortens itself
    // rather than squeeze the title out.
    final loose = BoxConstraints.loose(Size(size.width * 0.42, size.height));
    var startWidth = 0.0, endWidth = 0.0;
    Size? startSize, endSize;
    if (hasChild(_BarSlot.start)) {
      startSize = layoutChild(_BarSlot.start, loose);
      startWidth = startSize.width;
    }
    if (hasChild(_BarSlot.end)) {
      endSize = layoutChild(_BarSlot.end, loose);
      endWidth = endSize.width;
    }
    final side = math.max(startWidth, endWidth);
    final clear = side == 0 ? 0.0 : side + _gap;
    final titleWidth = math.max(0.0, size.width - 2 * clear);
    final titleSize = layoutChild(
      _BarSlot.title,
      BoxConstraints(
        minWidth: titleWidth,
        maxWidth: titleWidth,
        maxHeight: size.height,
      ),
    );
    positionChild(
      _BarSlot.title,
      Offset(clear, (size.height - titleSize.height) / 2),
    );
    final ltr = direction == TextDirection.ltr;
    if (startSize != null) {
      positionChild(
        _BarSlot.start,
        Offset(
          ltr ? 0 : size.width - startSize.width,
          (size.height - startSize.height) / 2,
        ),
      );
    }
    if (endSize != null) {
      positionChild(
        _BarSlot.end,
        Offset(
          ltr ? size.width - endSize.width : 0,
          (size.height - endSize.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_BarLayout old) => old.direction != direction;
}

/// A text button in the bar of a tablet's form sheet: "Cancel", or "‹ Back"
/// with a chevron.
class _BarTextButton extends StatelessWidget {
  final String label;
  final bool chevron;
  final VoidCallback onTap;

  const _BarTextButton({
    super.key,
    required this.label,
    required this.chevron,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chevron)
                Icon(Icons.chevron_left_rounded, size: 28, color: palette.link),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: chevron ? 0 : 4,
                  end: 4,
                ),
                child: Text(
                  label,
                  style: palette.body(17).copyWith(color: palette.link),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

/// Pages inside one sheet, as the navigation stack of a native iOS sheet.
/// [pages] is the stack, the first at the bottom, each with a key of its own;
/// the last is shown. A new last page slides in from the right over the one
/// under it, which moves a third of the way left; a removed one slides back
/// out. A horizontal swipe on a subpage takes it back the iOS way: it follows
/// the finger, and past half way or with a flick it calls [onBack], which
/// removes it.
///
/// A [GlassSheetPage] slides only its body: its bar (the titles fade into
/// each other) and its pinned part stay where they are, so the sheet's top
/// does not move between steps. Any other page slides as a whole when it is
/// wrapped in a [GlassSheetPageMotion].
class GlassSheetPages extends StatefulWidget {
  final List<Widget> pages;
  final VoidCallback onBack;

  const GlassSheetPages({super.key, required this.pages, required this.onBack});

  /// Values the pages keep for the next page (e.g. where a progress bar
  /// stood, so the next one fills on from there); null outside the pages.
  static Map<Object, Object?>? memoryOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>()?.memory;

  /// Whether the page around [context] is the one on top (or not in pages
  /// at all), not the one under it.
  static bool isTopPage(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>()?.top ?? true;

  @override
  State<GlassSheetPages> createState() => _GlassSheetPagesState();
}

class _GlassSheetPagesState extends State<GlassSheetPages>
    with SingleTickerProviderStateMixin {
  /// 1 when the top page is fully in, 0 when it is out to the right.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  )..addListener(() => _moving.value = _slide.value < 1);

  /// What is on screen: [GlassSheetPages.pages], plus a page that is sliding
  /// out after it was removed.
  late List<Widget> _shown = widget.pages;

  /// See [GlassSheetPages.memoryOf].
  final _memory = <Object, Object?>{};

  /// See [_SheetPageRole.fadeIn]. In time with [_slide], also when it is
  /// dragged.
  late final _fadeIn = _slide.drive(CurveTween(curve: const Interval(0.4, 1)));
  late final _fadeOut = ReverseAnimation(
    _slide.drive(CurveTween(curve: const Interval(0, 0.6))),
  );

  /// What each page has in its bar, by page key (see [_SheetPageRole.chrome]).
  final _chrome = <Object?, _Chrome>{};

  /// The pages with buttons held in place (see [GlassSheetHold]).
  final _held = <Object?>{};

  /// Whether a page is coming in or going out ([_slide] below 1).
  final _moving = ValueNotifier(false);

  /// The top page was swiped out; its removal needs no animation of its own.
  bool _swipedOut = false;
  bool _dragging = false;

  /// Only a subpage (not one sliding out) can be swiped back.
  bool get _canSwipe => widget.pages.length > 1 && _shown.length > 1;

  @override
  void didUpdateWidget(GlassSheetPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    final added = widget.pages.length > oldWidget.pages.length;
    final removed = widget.pages.length < oldWidget.pages.length;
    if (added) {
      _shown = widget.pages;
      _slide.value = 0;
      _slide.animateTo(1, curve: Curves.easeOutCubic);
    } else if (removed && !_swipedOut) {
      // Slides the removed page out over the page under it, then drops it.
      _shown = [...widget.pages, oldWidget.pages.last];
      _slide.animateBack(0, curve: Curves.easeInOutCubic).whenCompleteOrCancel(
        () {
          if (!mounted) return;
          setState(() => _shown = widget.pages);
          _slide.value = 1;
        },
      );
    } else if (_swipedOut) {
      _swipedOut = false;
      _shown = widget.pages;
      _slide.value = 1;
    } else if (_shown.length > oldWidget.pages.length) {
      // Rebuilt while a page slides out (the keyboard going, say): it slides
      // on, with the pages under it as they are now.
      _shown = [...widget.pages, _shown.last];
    } else {
      // Rebuilt while a page slides in (the keyboard of its field coming up,
      // say): the slide goes on instead of jumping to its end.
      _shown = widget.pages;
    }
  }

  @override
  void dispose() {
    _moving.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _dragUpdate(DragUpdateDetails d, double width) {
    _slide.value -= (d.primaryDelta ?? 0) / width;
  }

  void _dragEnd(double velocity) {
    _dragging = false;
    final back = velocity > 500 || (velocity >= -100 && _slide.value < 0.5);
    if (!back) {
      _slide.animateTo(1, curve: Curves.easeOutCubic);
      return;
    }
    _slide.animateBack(0, curve: Curves.easeOutCubic).whenComplete(() {
      if (!mounted) return;
      _swipedOut = true;
      widget.onBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = _shown.last;
    final under = _shown.length > 1 ? _shown[_shown.length - 2] : null;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _canSwipe
            ? (_) {
                // Takes over from a slide, as on iOS.
                _slide.stop();
                _dragging = true;
              }
            : null,
        onHorizontalDragUpdate: _canSwipe
            ? (d) {
                if (_dragging) _dragUpdate(d, constraints.maxWidth);
              }
            : null,
        onHorizontalDragEnd: _canSwipe
            ? (d) {
                if (_dragging) _dragEnd(d.velocity.pixelsPerSecond.dx);
              }
            : null,
        onHorizontalDragCancel: _canSwipe
            ? () {
                if (_dragging) _dragEnd(0);
              }
            : null,
        child: AnimatedBuilder(
          // Rebuilds the stack only when a slide starts or ends; the slide
          // itself moves layers (see _SheetPageRole.slide).
          animation: _moving,
          builder: (context, _) {
            final moving = _moving.value;
            // With reduced motion the pages fade into each other instead of
            // sliding.
            final reduce = MediaQuery.disableAnimationsOf(context);
            final leaving = _shown.length > widget.pages.length;
            return Stack(
              fit: StackFit.expand,
              children: [
                // The page under the top one, then the top one. Both have the
                // same wrappers, keyed by the page, so a page that moves from
                // one place to the other keeps its state (its scroll, its
                // fields, its pictures) instead of being built anew.
                for (final page in _shown)
                  if (page == under || page == top)
                    _place(
                      page,
                      other: page == top ? under?.key : top.key,
                      top: page == top,
                      moving: moving,
                      reduce: reduce,
                      leaving: leaving,
                      width: constraints.maxWidth,
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _place(
    Widget page, {
    required Key? other,
    required bool top,
    required bool moving,
    required bool reduce,
    required bool leaving,
    required double width,
  }) {
    final shown = top || moving;
    return KeyedSubtree(
      key: ValueKey(("page", page.key)),
      // The top page is a route of its own for screen readers, so a new step
      // is announced by its title and focused.
      child: Semantics(
        scopesRoute: top,
        explicitChildNodes: true,
        // The page underneath, and a page on its way out, hold no focus: a
        // field on it gives up its keyboard, and autofocus can't take it.
        child: ExcludeFocus(
          excluding: !top || leaving,
          // The page underneath shows only while the top one moves.
          child: Offstage(
            offstage: !shown,
            child: TickerMode(
              enabled: shown,
              // Its heroes stay out of flights while it is hidden.
              child: HeroMode(
                enabled: shown,
                child: _SheetPageRole(
                  top: top,
                  animation: _slide,
                  moving: moving && (top ? _shown.length > 1 : true),
                  reduce: reduce,
                  width: width,
                  memory: _memory,
                  fadeIn: _fadeIn,
                  fadeOut: _fadeOut,
                  chrome: _chrome,
                  held: _held,
                  pageKey: page.key,
                  otherKey: moving ? other : null,
                  child: page,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a page of [GlassSheetPages] is while pages change: on top or under
/// it, the [animation] (1 when the top page is fully in), and with [reduce] a fade
/// instead of a slide. It changes only when a slide starts or ends: the slide
/// itself moves and fades layers through [animation], so nothing rebuilds per
/// frame.
class _SheetPageRole extends InheritedWidget {
  final bool top;
  final Animation<double> animation;

  /// The top page is coming in or going out over a page under it.
  final bool moving;
  final bool reduce;

  /// The width the pages slide across.
  final double width;
  final Map<Object, Object?> memory;

  /// The opacity of what is in the top page's bar alone, and of what is in
  /// the other page's alone: the one goes before the other comes, so two
  /// titles are never both half there.
  final Animation<double> fadeIn;
  final Animation<double> fadeOut;

  /// What each page has in its bar, by page key: a [GlassSheetPage] notes
  /// its own as it builds, and reads the other page's ([otherKey]) to fade
  /// what they do not share.
  final Map<Object?, _Chrome> chrome;

  /// The pages with buttons held in place (see [GlassSheetHold]).
  final Set<Object?> held;
  final Key? pageKey;

  /// The page this one changes with while [moving]; null otherwise.
  final Key? otherKey;

  const _SheetPageRole({
    required this.top,
    required this.animation,
    required this.moving,
    required this.reduce,
    required this.width,
    required this.memory,
    required this.fadeIn,
    required this.fadeOut,
    required this.chrome,
    required this.held,
    required this.pageKey,
    required this.otherKey,
    required super.child,
  });

  /// What the page this one changes with has in its bar; null when pages
  /// are not changing, or it is not a [GlassSheetPage].
  _Chrome? get other => otherKey == null ? null : chrome[otherKey];

  /// How a part of this page that the other page lacks shows: fading in on
  /// top, out underneath.
  Animation<double> get ownOpacity => top ? fadeIn : fadeOut;

  /// [child] where this page is: the content slides over, the top page in
  /// from the right as the one under it goes out to the left, side by side
  /// (or, with reduced motion, the one fades into the other).
  Widget slide(Widget child) {
    if (reduce) {
      return FadeTransition(
        opacity: top ? animation : ReverseAnimation(animation),
        child: child,
      );
    }
    return _Slide(
      animation: animation,
      from: top ? 1 : 0,
      to: top ? 0 : -1,
      child: child,
    );
  }

  /// How far [slide] has moved this page, as a fraction of [width].
  double get slidOffset {
    if (reduce) return 0;
    final t = animation.value;
    return top ? 1 - t : -t;
  }

  /// How the title of this page shows: fading in on top, out underneath.
  Animation<double>? get titleOpacity => !moving ? null : ownOpacity;

  static _SheetPageRole? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>();

  @override
  bool updateShouldNotify(_SheetPageRole old) =>
      top != old.top ||
      animation != old.animation ||
      moving != old.moving ||
      reduce != old.reduce ||
      width != old.width ||
      otherKey != old.otherKey;
}

/// What a [GlassSheetPage] has in its bar.
typedef _Chrome = ({bool back, bool pinned, bool action});

/// Moves [child] sideways by a fraction of its width, from [from] (slide 0)
/// to [to] (slide 1), repainting only.
class _Slide extends AnimatedWidget {
  final double from;
  final double to;
  final Widget child;

  const _Slide({
    required Animation<double> animation,
    required this.from,
    required this.to,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return FractionalTranslation(
      translation: Offset(from + (to - from) * t, 0),
      child: child,
    );
  }
}

/// The buttons of a page of [GlassSheetPages] (its bottom bar, or the
/// actions of a [SheetSplit]): they stay in place while the content slides
/// over to the next page. When both pages have them, the new page's take
/// their place at once; when only one does, they fade.
class GlassSheetHold extends StatefulWidget {
  final Widget child;

  const GlassSheetHold({super.key, required this.child});

  @override
  State<GlassSheetHold> createState() => _GlassSheetHoldState();
}

class _GlassSheetHoldState extends State<GlassSheetHold> {
  _SheetPageRole? _role;

  @override
  void dispose() {
    _role?.held.remove(_role?.pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = _role = _SheetPageRole.maybeOf(context);
    if (role == null) return widget.child;
    role.held.add(role.pageKey);
    final otherKey = role.otherKey;
    if (otherKey == null) return widget.child;
    final otherHeld = role.held.contains(otherKey);
    if (!otherHeld && !role.top) {
      // The new page builds after this one: look again once it has
      // noted its buttons.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && role.held.contains(otherKey)) setState(() {});
      });
    }
    // Both pages have buttons: the top page's stand in for the other's.
    final Widget shown = otherHeld
        ? Visibility(
            visible: role.top,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: widget.child,
          )
        : FadeTransition(opacity: role.ownOpacity, child: widget.child);
    return IgnorePointer(
      ignoring: !role.top,
      child: AnimatedBuilder(
        animation: role.animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(-role.slidOffset * role.width, 0),
          child: child,
        ),
        child: shown,
      ),
    );
  }
}

/// A page of [GlassSheetPages] that is not a [GlassSheetPage] (e.g. screens
/// with their own navigator): it slides in and out as a whole.
class GlassSheetPageMotion extends StatelessWidget {
  final Widget child;

  const GlassSheetPageMotion({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      _SheetPageRole.maybeOf(context)?.slide(child) ?? child;
}

/// One page of a sheet: its [GlassSheetHeader], [child] in a
/// [GlassSheetScrollView], and [bottom] (a button) pinned to the bottom of
/// the sheet, as on a full screen.
///
/// The content scrolls on under the header and the [pinned] part; once it
/// is under them, they get the hard scroll edge of iOS ([ScrollEdgeBand]).
class GlassSheetPage extends StatefulWidget {
  final String title;

  /// In the title's place while not null (see [GlassSheetHeader.titleWidget]).
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view, for a long
  /// list.
  final List<Widget>? slivers;
  final Widget? bottom;

  /// The way on: at the bottom on a phone held upright (under [bottom]), in
  /// the bar at the top right elsewhere ([sheetActionInBar]). Screens inside
  /// the page can put theirs in its [SheetActionSlot] instead.
  final SheetAction? action;

  /// False on a page that is done ("Success"): no close button, no
  /// "Cancel" in the bar; its way on is the way out.
  final bool closable;

  /// Right under the title bar, the full width of the sheet, and above the
  /// scrolling [child], staying put while the page scrolls (the progress of
  /// adding a card).
  final Widget? pinned;

  /// On a phone held sideways: a second line under the title (see
  /// [GlassSheetHeader.subtitle]).
  final Widget? subtitle;

  /// Around [child] in the scroll view; zero when [child] pads itself.
  final EdgeInsets padding;

  /// False for a [child] that fills the page and fits itself to it (a PIN
  /// pad) instead of scrolling.
  final bool scrolls;

  /// With [scrolls] false: [child] keeps clear of the home indicator itself
  /// (screens with their own bottom bar), so the page adds no room for it.
  final bool childClearsBottom;

  /// Whether the bar gets the hard scroll edge once content scrolls under
  /// it. Without it, only the buttons float over the content (a page whose
  /// bar has no title).
  final bool edge;

  const GlassSheetPage({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.child,
    this.slivers,
    this.bottom,
    this.action,
    this.closable = true,
    this.pinned,
    this.subtitle,
    this.padding = EdgeInsets.zero,
    this.scrolls = true,
    this.childClearsBottom = false,
    this.edge = true,
  }) : assert((child == null) != (slivers == null), "child or slivers"),
       assert(scrolls || child != null, "a page that fills itself has a child");

  @override
  State<GlassSheetPage> createState() => _GlassSheetPageState();
}

class _GlassSheetPageState extends State<GlassSheetPage> {
  final _under = ScrollEdgeNotifier();
  final _slot = SheetActionSlot();

  @override
  void dispose() {
    _under.dispose();
    _slot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final role = _SheetPageRole.maybeOf(context);
    final title = widget.title;
    final onBack = widget.onBack;
    final pinned = widget.pinned;
    final action = widget.action;
    final inBar = sheetActionInBar(context);
    role?.chrome[role.pageKey] = (
      back: onBack != null,
      pinned: pinned != null,
      action: inBar && (action != null || _slot.action != null),
    );
    // While pages change, what only one of the two pages has fades; what
    // both have stays put (the top page's stands in for the other's).
    final moving = role != null && role.otherKey != null;
    final other = role?.other;
    if (moving && other == null) {
      // The other page builds after this one, the first time: look again
      // once it has noted its bar. Until then, nothing fades.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && role.other != null) setState(() {});
      });
    }
    final top = role?.top ?? true;
    final pinnedFades = moving && other != null && !other.pinned;
    // Underneath, the top page's pinned part stands in for this one, unless
    // it has none.
    Widget? pinnedShown(Widget? pinned) => pinned == null
        ? null
        : Visibility(
            visible: top || pinnedFades,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: pinnedFades
                ? FadeTransition(opacity: role.ownOpacity, child: pinned)
                : pinned,
          );
    final head = <Widget>[
      // In pages the bar stays put while pages change; only the titles fade
      // into each other. The way on in the bar comes from the page, or from
      // a screen inside it (the slot).
      ListenableBuilder(
        listenable: _slot,
        builder: (context, _) {
          final slotted = action == null ? _slot.action : null;
          return GlassSheetHeader(
            title: title,
            titleWidget: widget.titleWidget,
            onBack: onBack,
            action: inBar ? (action ?? slotted) : null,
            onAction: slotted == null
                ? null
                : () => _slot.action?.onTap?.call(),
            closable: widget.closable,
            buttons: top,
            titleOpacity: role?.titleOpacity,
            backOpacity: moving && other != null && !other.back
                ? role.ownOpacity
                : null,
            actionOpacity: moving && other != null && !other.action
                ? role.ownOpacity
                : null,
            subtitle: widget.subtitle,
          );
        },
      ),
      // The progress: a line the full width of the sheet, under the bar.
      ?pinnedShown(pinned),
    ];
    final body = ScrollEdgeListener(
      notifier: _under,
      child: Column(
        mainAxisSize: role == null ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _body(context, inBar ? null : action),
      ),
    );
    // Taps on the bar stay on the bar, also where content is under it.
    final bar = Listener(
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Clipped to the sheet's top corners itself: its blur doesn't
          // follow the sheet's rounded clip, and filled the corners square.
          if (widget.edge)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: _GlassSheet._radius,
                ),
                child: ScrollEdgeBand(under: _under, color: palette.sheet),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: head,
          ),
        ],
      ),
    );
    return SheetActionSlotScope(
      slot: _slot,
      child: BarOverBody(
        expand: role != null,
        bar: bar,
        body: role == null ? body : role.slide(body),
      ),
    );
  }

  /// What scrolls, and the buttons under it: [GlassSheetPage.bottom] and
  /// [action] (the way on, when it is not in the bar).
  List<Widget> _body(BuildContext context, SheetAction? action) {
    final padding = widget.padding;
    final child = widget.child;
    final slivers = widget.slivers;
    final button = action == null
        ? null
        : SheetActionRow(
            primaryKey: action.key,
            primaryLabel: action.label,
            onPrimary: action.enabled ? action.onTap : null,
            primaryLeading: action.busy ? const SheetBusySpinner() : null,
          );
    final given = widget.bottom;
    final bottom = button == null
        ? given
        : given == null
        ? button
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [given, button],
          );
    return [
      if (!widget.scrolls) ...[
        Expanded(
          child: Padding(
            padding: widget.childClearsBottom || bottom != null
                ? padding
                : padding.add(
                    EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
            child: child,
          ),
        ),
        if (bottom != null) SheetBottomBar(child: bottom),
      ] else if (bottom == null)
        Flexible(
          child: GlassSheetScrollView(
            padding: padding,
            slivers: slivers,
            child: child,
          ),
        )
      else ...[
        Expanded(
          // Cut off where the bottom (a note, the buttons) starts, so the
          // content doesn't run on under it as text over text; open at the
          // top, where it goes on under the header.
          child: ClipRect(
            clipper: const _OpenTopClipper(),
            child: GlassSheetScrollView(
              padding: padding,
              clearBottom: false,
              slivers: slivers,
              child: child,
            ),
          ),
        ),
        SheetBottomBar(child: bottom),
      ],
    ];
  }
}

/// The scrolling body of a sheet, under its [GlassSheetHeader]: it pulls the
/// sheet down from its top (see [GlassSheetScope]), goes on under the header
/// (which clips it no more than the sheet does; see [GlassSheetPage]), and
/// ends clear of the home indicator. [child] pads itself from the
/// sides unless [padding] does.
class GlassSheetScrollView extends StatelessWidget {
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view (a long
  /// list).
  final List<Widget>? slivers;
  final EdgeInsets padding;

  /// Ends clear of the home indicator; off when a button sits under it.
  final bool clearBottom;

  const GlassSheetScrollView({
    super.key,
    this.child,
    this.slivers,
    this.padding = EdgeInsets.zero,
    this.clearBottom = true,
  }) : assert((child == null) != (slivers == null), "child or slivers");

  /// Room between the header and the content at rest.
  static const _top = 6.0;

  @override
  Widget build(BuildContext context) {
    // Not clipped at the top: under a [GlassSheetPage]'s header the content
    // goes on, blurred. The page clips the bottom.
    return switch (slivers) {
      final slivers? => CustomScrollView(
        physics: glassSheetScrollPhysics(context),
        clipBehavior: Clip.none,
        slivers: [
          SliverPadding(
            padding: _padding(context),
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      ),
      null => SingleChildScrollView(
        physics: glassSheetScrollPhysics(context),
        clipBehavior: Clip.none,
        padding: _padding(context),
        child: child,
      ),
    };
  }

  EdgeInsets _padding(BuildContext context) => padding.copyWith(
    top: padding.top + _top,
    bottom:
        padding.bottom +
        (clearBottom ? MediaQuery.paddingOf(context).bottom : 16),
  );
}

/// A sheet with the title [titleKey] over [child]: a [GlassSheetPage] in
/// [showGlassSheet].
Future<void> showTitledGlassSheet({
  required BuildContext context,
  required String titleKey,
  required Widget child,
}) => showGlassSheet<void>(
  context: context,
  builder: (context) => GlassSheetPage(
    title: FlutterI18n.translate(context, titleKey),
    child: child,
  ),
);

/// Tells the page under an open sheet that it is covered: its glass and
/// scroll edges stop blurring ([GlassScope.covered]) while a sheet is fully
/// open, and blur again as it starts to close. The sheet covers all of the
/// page but a dimmed strip at the top, so that blur, redone every frame,
/// could not be seen. Wraps the app's pages, and also carries the developer
/// setting [opaqueGlass] ([GlassOpaque]).
class GlassSheetCover extends StatelessWidget {
  /// How many sheets are fully open.
  static final covering = ValueNotifier<int>(0);

  final Widget child;
  final bool opaqueGlass;

  const GlassSheetCover({
    super.key,
    required this.child,
    this.opaqueGlass = false,
  });

  @override
  Widget build(BuildContext context) => GlassOpaque(
    opaque: opaqueGlass,
    child: ValueListenableBuilder<int>(
      valueListenable: covering,
      builder: (context, n, child) => GlassScope(covered: n > 0, child: child!),
      child: child,
    ),
  );
}

/// Clips at the bottom and the sides' far reaches only: open above, so a
/// sheet's content can go on under its header.
class _OpenTopClipper extends CustomClipper<Rect> {
  const _OpenTopClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, -size.height * 4, size.width * 2, size.height);

  @override
  bool shouldReclip(_OpenTopClipper oldClipper) => false;
}
