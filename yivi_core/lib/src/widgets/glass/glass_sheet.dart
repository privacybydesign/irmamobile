import "package:flutter/scheduler.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

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
                // Every sheet as tall as the dialog may be, as on the phone.
                height: MediaQuery.sizeOf(context).height * 0.85,
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
    animation?.removeStatusListener(_onCoverStatus);
    _cover(false);
    _pull.dispose();
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

  void _cover(bool covering) {
    if (covering == _covering) return;
    _covering = covering;
    GlassSheetCover.covering.value += covering ? 1 : -1;
  }

  void _onCoverStatus(AnimationStatus status) =>
      _cover(status == AnimationStatus.completed);

  @override
  void install() {
    super.install();
    animation!.addStatusListener(_onCoverStatus);
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
    // Opaque and not blurred: the glass fill let only a trace of the blurred
    // page through, and that blur, redone every frame over the whole sheet,
    // was the costliest thing on screen. The fill over the dimmed page, as
    // it looked, made solid.
    final fill = Color.alphaBlend(
      palette.glassStrongFill,
      Color.alphaBlend(_GlassSheetRoute.barrier, palette.background),
    );
    return GlassSurface(
      key: const Key("glass_sheet"),
      fill: fill,
      blur: false,
      shape: shape,
      // Glass on the sheet would only blur its flat colour; the sheet's own
      // scroll edge does blur its content (it is not covered).
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
                child: child,
              ),
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
  static Duration _switch(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 200);

  final String title;

  /// In the title's place while not null (Add data's search field, once the
  /// list has scrolled it away): between the buttons, the title faded out.
  final Widget? titleWidget;
  final VoidCallback? onBack;

  /// The title fades while pages of [GlassSheetPages] change (the bar
  /// itself stays put); null when it simply shows.
  final Animation<double>? titleOpacity;

  /// The back button fades in or out while pages change, when the page it
  /// comes from or goes back to has none; null when it simply shows.
  final Animation<double>? backOpacity;

  /// Off for the page under the top one: its buttons sit under the top
  /// page's own.
  final bool buttons;

  /// On a phone held sideways: after the title, before the close button
  /// (the progress of adding a card).
  final Widget? trailing;

  /// On a phone held sideways: a second line under the title (who a card is
  /// added for).
  final Widget? subtitle;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.titleOpacity,
    this.backOpacity,
    this.buttons = true,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (usePhoneLandscape(context)) return _row(context);
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
                child: AnimatedOpacity(
                  // Gone while a widget takes its place; it still names the
                  // page.
                  opacity: titleWidget == null ? 1 : 0,
                  duration: _switch(context),
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
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              // Where the buttons are, also on the page under the top one
              // (which draws none): it must not get wider while it fades.
              start: onBack != null ? 52 : 0,
              end: 52,
              top: 0,
              bottom: 0,
              // Fades with the title while pages change, as the title would.
              child: FadeTransition(
                opacity: titleOpacity ?? kAlwaysCompleteAnimation,
                child: AnimatedSwitcher(
                  duration: _switch(context),
                  child: titleWidget == null
                      ? const SizedBox.shrink()
                      : KeyedSubtree(
                          key: const ValueKey("glass_sheet_title_widget"),
                          child: Center(child: titleWidget),
                        ),
                ),
              ),
            ),
            if (onBack != null && buttons)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FadeTransition(
                  opacity: backOpacity ?? kAlwaysCompleteAnimation,
                  child: YiviBackButton(onTap: onBack),
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

  /// A phone held sideways: one row, so the content gets the height. The
  /// back button, the title at the start (with [subtitle] under it), then
  /// the search field ([titleWidget], next to the title rather than in its
  /// place) or [trailing], and the close button.
  Widget _row(BuildContext context) {
    final palette = YiviPalette.of(context);
    final titleWidget = this.titleWidget;
    final trailing = this.trailing;
    final subtitle = this.subtitle;
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette
                .display(17)
                .copyWith(height: 20 / 17, color: palette.text),
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            if (titleWidget != null) ...[
              heading,
              Expanded(
                child: FadeTransition(
                  opacity: titleOpacity ?? kAlwaysCompleteAnimation,
                  child: titleWidget,
                ),
              ),
            ] else ...[
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: heading,
                ),
              ),
              ?trailing,
            ],
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

  /// See [_SheetPageRole.fadeIn]. In time with [_slide], also when it is
  /// dragged.
  late final _fadeIn = _slide.drive(CurveTween(curve: const Interval(0.4, 1)));
  late final _fadeOut = ReverseAnimation(
    _slide.drive(CurveTween(curve: const Interval(0, 0.6))),
  );

  /// What each page has in its bar, by page key (see [_SheetPageRole.chrome]).
  final _chrome = <Object?, _Chrome>{};

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
                      other: page == top ? under?.key : top.key,
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
    required Key? other,
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
                  fadeIn: _fadeIn,
                  fadeOut: _fadeOut,
                  chrome: _chrome,
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

  /// Behind what slides of the top page while it moves.
  final Color? shade;
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
  final Key? pageKey;

  /// The page this one changes with while [moving]; null otherwise.
  final Key? otherKey;

  const _SheetPageRole({
    required this.top,
    required this.animation,
    required this.moving,
    required this.reduce,
    required this.shade,
    required this.memory,
    required this.fadeIn,
    required this.fadeOut,
    required this.chrome,
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
  Animation<double>? get titleOpacity => !moving ? null : ownOpacity;

  static _SheetPageRole? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>();

  @override
  bool updateShouldNotify(_SheetPageRole old) =>
      top != old.top ||
      animation != old.animation ||
      moving != old.moving ||
      reduce != old.reduce ||
      shade != old.shade ||
      otherKey != old.otherKey;
}

/// What a [GlassSheetPage] has in its bar.
typedef _Chrome = ({bool back, bool pinned});

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

  /// Under the title bar and above the scrolling [child], staying put while
  /// the page scrolls (e.g. the progress of adding a card).
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

  const GlassSheetPage({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.child,
    this.slivers,
    this.bottom,
    this.pinned,
    this.subtitle,
    this.padding = EdgeInsets.zero,
    this.scrolls = true,
    this.childClearsBottom = false,
  }) : assert((child == null) != (slivers == null), "child or slivers"),
       assert(scrolls || child != null, "a page that fills itself has a child");

  @override
  State<GlassSheetPage> createState() => _GlassSheetPageState();
}

class _GlassSheetPageState extends State<GlassSheetPage> {
  final _under = ScrollEdgeNotifier();

  @override
  void dispose() {
    _under.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final role = _SheetPageRole.maybeOf(context);
    final title = widget.title;
    final onBack = widget.onBack;
    final pinned = widget.pinned;
    role?.chrome[role.pageKey] = (back: onBack != null, pinned: pinned != null);
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
    // A phone held sideways: the pinned part (the progress) goes in the bar,
    // after the title.
    final inBar = usePhoneLandscape(context);
    final head = <Widget>[
      // In pages the bar stays put while pages change; only the titles fade
      // into each other.
      GlassSheetHeader(
        title: title,
        titleWidget: widget.titleWidget,
        onBack: onBack,
        buttons: top,
        titleOpacity: role?.titleOpacity,
        backOpacity: moving && other != null && !other.back
            ? role.ownOpacity
            : null,
        trailing: inBar ? pinnedShown(pinned) : null,
        subtitle: inBar ? widget.subtitle : null,
      ),
      if (pinned != null && !inBar)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: pinnedShown(pinned),
        ),
    ];
    final body = ScrollEdgeListener(
      notifier: _under,
      child: Column(
        mainAxisSize: role == null ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _body(context),
      ),
    );
    // Taps on the bar stay on the bar, also where content is under it.
    final bar = Listener(
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Clipped to the sheet's top corners itself: its blur doesn't
          // follow the sheet's rounded clip, and filled the corners square.
          Positioned.fill(
            child: ClipRSuperellipse(
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
    return BarOverBody(
      expand: role != null,
      bar: bar,
      body: role == null ? body : role.slide(body),
    );
  }

  /// What scrolls, and the button under it.
  List<Widget> _body(BuildContext context) {
    final bottom = widget.bottom;
    final padding = widget.padding;
    final child = widget.child;
    final slivers = widget.slivers;
    return [
      if (!widget.scrolls)
        Expanded(
          child: Padding(
            padding: widget.childClearsBottom
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
