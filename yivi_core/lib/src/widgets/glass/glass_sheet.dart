import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../irma_close_button.dart";
import "../pull_to_dismiss_physics.dart";
import "glass_surface.dart";

/// Shows [builder]'s content in the app's one sheet: a full-width glass sheet
/// attached to the bottom of the screen, at least [minHeightFraction] of the
/// screen tall (or exactly [heightFraction]), that closes on a tap outside it
/// or a drag down. It is a page route, so a [Hero] can fly into it. On
/// tablets it is a centred dialog with the same look.
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
  void _settle({required bool close}) {
    var settled = false;
    void done(AnimationStatus status) {
      if (settled || status.isAnimating) return;
      settled = true;
      controller?.removeStatusListener(done);
      _stopGesture();
    }

    controller!.addStatusListener(done);
    if (close) {
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

  double _measure(BuildContext context) =>
      _sheetHeight = context.size?.height ?? _sheetHeight;

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
    return Padding(
      // Rides up on the keyboard.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
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
                // Dragging the sheet outside its list (its header).
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
  final Widget child;

  const _GlassSheet({
    required this.attached,
    required this.height,
    this.bottomInset = 0,
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
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: 0, bottom: 20 + bottomInset),
              viewPadding: media.viewPadding.copyWith(top: 0),
            ),
            child: child,
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

  const GlassSheetHeader({super.key, required this.title, this.onBack});

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
              child: Semantics(
                header: true,
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
            if (onBack != null)
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
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IrmaCloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pages inside one sheet, as the navigation stack of a native iOS sheet.
/// [pages] is the stack, the first at the bottom, each with a key of its own;
/// the last is shown. A new last page slides in from the right over the one
/// under it, which moves a third of the way left; a removed one slides back
/// out. A horizontal swipe on a subpage takes it back the iOS way: it follows
/// the finger, and past half way or with a flick it calls [onBack], which
/// removes it.
class GlassSheetPages extends StatefulWidget {
  final List<Widget> pages;
  final VoidCallback onBack;

  const GlassSheetPages({super.key, required this.pages, required this.onBack});

  @override
  State<GlassSheetPages> createState() => _GlassSheetPagesState();
}

class _GlassSheetPagesState extends State<GlassSheetPages>
    with SingleTickerProviderStateMixin {
  /// 1 when the top page is fully in, 0 when it is out to the right.
  late final _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );

  /// What is on screen: [GlassSheetPages.pages], plus a page that is sliding
  /// out after it was removed.
  late List<Widget> _shown = widget.pages;

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
          animation: _slide,
          builder: (context, _) {
            final t = _slide.value;
            final moving = t < 1;
            return Stack(
              fit: StackFit.expand,
              children: [
                // The page under the top one: kept (and so its scroll), shown
                // only while the top one moves.
                for (final page in _shown)
                  if (page == under)
                    KeyedSubtree(
                      key: ValueKey(("under", page.key)),
                      child: Offstage(
                        offstage: !moving,
                        child: TickerMode(
                          enabled: moving,
                          // Its heroes stay out of flights while it is hidden.
                          child: HeroMode(
                            enabled: moving,
                            child: FractionalTranslation(
                              translation: Offset(-0.3 * t, 0),
                              child: page,
                            ),
                          ),
                        ),
                      ),
                    ),
                KeyedSubtree(
                  key: ValueKey(("top", top.key)),
                  child: FractionalTranslation(
                    translation: Offset(1 - t, 0),
                    // While it moves it has the sheet's colour behind it, as
                    // a page in a native sheet does, so the page under it
                    // does not show through the glass.
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: moving && under != null
                            ? palette.sheet
                            : const Color(0x00000000),
                        boxShadow: moving && under != null
                            ? const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: top,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One page of a sheet: its [GlassSheetHeader], [child] in a
/// [GlassSheetScrollView], and [bottom] (a button) pinned to the bottom of
/// the sheet, as on a full screen.
class GlassSheetPage extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget child;
  final Widget? bottom;

  /// Around [child] in the scroll view; zero when [child] pads itself.
  final EdgeInsets padding;

  const GlassSheetPage({
    super.key,
    required this.title,
    this.onBack,
    required this.child,
    this.bottom,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSheetHeader(title: title, onBack: onBack),
        if (bottom == null)
          Flexible(
            child: GlassSheetScrollView(padding: padding, child: child),
          )
        else ...[
          Expanded(
            child: GlassSheetScrollView(
              padding: padding,
              clearBottom: false,
              child: child,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.paddingOf(context).bottom,
            ),
            child: bottom,
          ),
        ],
      ],
    );
  }
}

/// The scrolling body of a sheet, under its [GlassSheetHeader]: it pulls the
/// sheet down from its top (see [GlassSheetScope]), fades out under the
/// header, and ends clear of the home indicator. [child] pads itself from the
/// sides unless [padding] does.
class GlassSheetScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  /// Ends clear of the home indicator; off when a button sits under it.
  final bool clearBottom;

  const GlassSheetScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.clearBottom = true,
  });

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
      child: SingleChildScrollView(
        physics: glassSheetScrollPhysics(context),
        padding: padding.copyWith(
          top: padding.top + _fade / 2,
          bottom:
              padding.bottom +
              (clearBottom ? MediaQuery.paddingOf(context).bottom : 16),
        ),
        child: child,
      ),
    );
  }
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
