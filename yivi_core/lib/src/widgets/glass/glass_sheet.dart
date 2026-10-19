import "package:flutter/scheduler.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../irma_close_button.dart";
import "../pull_to_dismiss_physics.dart";
import "floating_bar_placement.dart";
import "glass_surface.dart";

/// Shows [builder]'s content in the app's one sheet: a full-width glass sheet
/// attached to the bottom of the screen, at least [minHeightFraction] of the
/// screen tall (or exactly [heightFraction]), that closes on a tap outside it
/// or a drag down. It is a page route, so a [Hero] can fly into it. On
/// tablets it is a centred dialog with the same look.
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
  double minHeightFraction = 0.5,
  double? heightFraction,
}) {
  if (isExpandedLayout(context)) {
    return showDialog<T>(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: _GlassSheet(
                attached: false,
                height: heightFraction == null
                    ? null
                    : MediaQuery.sizeOf(context).height * heightFraction,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
  return Navigator.of(context).push(
    _GlassSheetRoute<T>(
      builder: builder,
      minHeightFraction: minHeightFraction,
      heightFraction: heightFraction,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

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

/// The route of a sheet: it slides up from the bottom over a dim barrier,
/// closes on a tap outside it, a drag down or a pull of its list, and is a
/// [PageRoute], so heroes fly into it (a modal bottom sheet is not).
class _GlassSheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final double minHeightFraction;
  final double? heightFraction;

  _GlassSheetRoute({
    required this.builder,
    required this.minHeightFraction,
    required this.heightFraction,
    required this.barrierLabel,
  }) {
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
        _dragStartedAtTop && animation?.status != AnimationStatus.reverse,
    onRelease: _onPullReleased,
  );

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
    _pull.dispose();
    super.dispose();
  }

  @override
  final String barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => const Color(0x470C1824);

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
    final maxHeight = screen - media.padding.top - 8;
    final height = heightFraction == null
        ? null
        : (screen * heightFraction!).clamp(0.0, maxHeight);
    // The sheet keeps its place and size when the keyboard comes up: only
    // its content ends above the keyboard (see _GlassSheet).
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (screen * minHeightFraction).clamp(0.0, maxHeight),
            maxHeight: maxHeight,
          ),
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
                onVerticalDragStart: (_) => _startGesture(),
                onVerticalDragUpdate: (d) =>
                    _drag(d.primaryDelta ?? 0, _measure(context)),
                onVerticalDragEnd: (d) =>
                    _release(d.velocity.pixelsPerSecond.dy),
                // Interrupted by the system: back in place.
                onVerticalDragCancel: () {
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
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AnimatedBuilder(
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
}

/// The look of every sheet: frosted glass, corners of 38 (concentric with a
/// 44 close button inset 16). Attached to the bottom edge it has square
/// bottom corners, which the screen's own corners round off.
class _GlassSheet extends StatelessWidget {
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

  static const _radius = Radius.circular(38);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: attached
          ? const BorderRadius.vertical(top: _radius)
          : const BorderRadius.all(_radius),
    );
    final media = MediaQuery.of(context);
    return GlassSurface(
      key: const Key("glass_sheet"),
      fill: palette.glassStrongFill,
      shape: shape,
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
                ),
                // The device's inset where the sheet meets the bottom edge, so a
                // button lands where it does on a full screen.
                viewPadding: media.viewPadding.copyWith(
                  top: 0,
                  bottom: attached ? media.viewPadding.bottom : 0,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of a sheet, as the navigation bar of a native iOS sheet: a
/// short centred title, the same round glass close button as on a full
/// screen, and a back button when [onBack] is set. Explanatory text goes at
/// the top of the sheet's scrolling content, not here.
class GlassSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  /// The title fades while pages of [GlassSheetPages] change (the bar
  /// itself stays put); null when it simply shows.
  final Animation<double>? titleOpacity;

  /// Off for the page under the top one: its buttons sit under the top
  /// page's own.
  final bool buttons;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.onBack,
    this.titleOpacity,
    this.buttons = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              // Clear of the buttons on both sides, so it stays centred.
              padding: const EdgeInsets.symmetric(horizontal: 56),
              // Names the page (see GlassSheetPages): a screen reader reads
              // it when the page comes in.
              child: Semantics(
                header: true,
                namesRoute: true,
                child: FadeTransition(
                  opacity: titleOpacity ?? kAlwaysCompleteAnimation,
                  // A new title on the same page (a screen changing below
                  // the bar) fades in over the old one.
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(title),
                      child: Text(
                        title,
                        key: const Key("glass_sheet_title"),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: palette
                            .display(17)
                            .copyWith(height: 22 / 17, color: palette.text),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onBack != null && buttons)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GlassIconButton(
                  semanticsLabel: FlutterI18n.translate(context, "ui.go_back"),
                  onTap: onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: palette.text,
                  ),
                ),
              ),
            if (buttons)
              Align(
                alignment: AlignmentDirectional.centerEnd,
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

/// Asks before the sheet around it closes, while [ask] is true: a tap outside
/// the sheet, a drag or pull down, its close button or the system back then
/// runs [confirm] instead, and the sheet closes only when that returns true.
/// While [ask] is false the sheet closes as usual.
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
    } else {
      _swipedOut = false;
      _shown = widget.pages;
      _slide.value = 1;
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
    final palette = YiviPalette.of(context);
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
                      top: page == top,
                      moving: moving,
                      reduce: reduce,
                      leaving: leaving,
                      shade: page == top && moving && under != null
                          ? palette.sheet
                          : null,
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
    required bool top,
    required bool moving,
    required bool reduce,
    required bool leaving,
    required Color? shade,
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
                  shade: shade,
                  memory: _memory,
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

  /// Behind what slides of the top page while it moves.
  final Color? shade;
  final Map<Object, Object?> memory;

  const _SheetPageRole({
    required this.top,
    required this.animation,
    required this.moving,
    required this.reduce,
    required this.shade,
    required this.memory,
    required super.child,
  });

  /// [child] where this page is: the top one slides in from the right (or
  /// fades in), the one under it moves a third of the way left.
  Widget slide(Widget child) {
    if (!top) {
      return reduce
          ? child
          : _Slide(animation: animation, from: 0, to: -0.3, child: child);
    }
    final shade = this.shade;
    final shaded = shade == null
        ? child
        : DecoratedBox(
            decoration: BoxDecoration(
              color: shade,
              boxShadow: const [
                BoxShadow(color: Color(0x1F000000), blurRadius: 16),
              ],
            ),
            child: child,
          );
    return reduce
        ? FadeTransition(opacity: animation, child: shaded)
        : _Slide(animation: animation, from: 1, to: 0, child: shaded);
  }

  /// How the title of this page shows: fading in on top, out underneath.
  Animation<double>? get titleOpacity => !moving
      ? null
      : top
      ? animation
      : ReverseAnimation(animation);

  static _SheetPageRole? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>();

  @override
  bool updateShouldNotify(_SheetPageRole old) =>
      top != old.top ||
      animation != old.animation ||
      moving != old.moving ||
      reduce != old.reduce ||
      shade != old.shade;
}

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
class GlassSheetPage extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view, for a long
  /// list.
  final List<Widget>? slivers;
  final Widget? bottom;

  /// Under the title bar and above the scrolling [child], staying put while
  /// the page scrolls (e.g. the progress of adding a card).
  final Widget? pinned;

  /// Around [child] in the scroll view; zero when [child] pads itself.
  final EdgeInsets padding;

  /// False for a [child] that fills the page and fits itself to it (a PIN
  /// pad) instead of scrolling.
  final bool scrolls;

  /// With [scrolls] false: [child] keeps clear of the home indicator itself
  /// (screens with their own bottom bar), so the page adds no room for it.
  final bool childClearsBottom;

  const GlassSheetPage({
    super.key,
    required this.title,
    this.onBack,
    this.child,
    this.slivers,
    this.bottom,
    this.pinned,
    this.padding = EdgeInsets.zero,
    this.scrolls = true,
    this.childClearsBottom = false,
  }) : assert((child == null) != (slivers == null), "child or slivers"),
       assert(scrolls || child != null, "a page that fills itself has a child");

  @override
  Widget build(BuildContext context) {
    final role = _SheetPageRole.maybeOf(context);
    final pinned = this.pinned;
    final head = <Widget>[
      // In pages the bar stays put while pages change; only the titles fade
      // into each other.
      GlassSheetHeader(
        title: title,
        onBack: onBack,
        buttons: role?.top ?? true,
        titleOpacity: role?.titleOpacity,
      ),
      if (pinned != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          // The top page's pinned part stands in for this one meanwhile.
          child: Visibility(
            visible: role?.top ?? true,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: pinned,
          ),
        ),
    ];
    final body = _body(context);
    if (role == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...head, ...body],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...head,
        Expanded(
          child: role.slide(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: body,
            ),
          ),
        ),
      ],
    );
  }

  /// What scrolls, and the button under it.
  List<Widget> _body(BuildContext context) {
    final bottom = this.bottom;
    return [
      if (!scrolls)
        Expanded(
          child: Padding(
            padding: childClearsBottom
                ? padding
                : padding.add(
                    EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
            child: child,
          ),
        )
      else if (bottom == null)
        Flexible(
          child: GlassSheetScrollView(
            padding: padding,
            slivers: slivers,
            child: child,
          ),
        )
      else ...[
        Expanded(
          child: GlassSheetScrollView(
            padding: padding,
            clearBottom: false,
            slivers: slivers,
            child: child,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            // The sheet ends at the screen's bottom edge.
            FloatingBarPlacement.buttonBottom(context),
          ),
          child: bottom,
        ),
      ],
    ];
  }
}

/// The scrolling body of a sheet, under its [GlassSheetHeader]: it pulls the
/// sheet down from its top (see [GlassSheetScope]), fades out under the
/// header, and ends clear of the home indicator. [child] pads itself from the
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

  /// How far the content fades out under the header.
  static const _fade = 12.0;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0x00000000), Color(0xFF000000)],
        stops: [0, (_fade / bounds.height).clamp(0.0, 1.0)],
      ).createShader(bounds),
      child: switch (slivers) {
        final slivers? => CustomScrollView(
          physics: glassSheetScrollPhysics(context),
          slivers: [
            SliverPadding(
              padding: _padding(context),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        ),
        null => SingleChildScrollView(
          physics: glassSheetScrollPhysics(context),
          padding: _padding(context),
          child: child,
        ),
      },
    );
  }

  EdgeInsets _padding(BuildContext context) => padding.copyWith(
    top: padding.top + _fade / 2,
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
  double minHeightFraction = 0.5,
}) => showGlassSheet<void>(
  context: context,
  minHeightFraction: minHeightFraction,
  builder: (context) => GlassSheetPage(
    title: FlutterI18n.translate(context, titleKey),
    child: child,
  ),
);
