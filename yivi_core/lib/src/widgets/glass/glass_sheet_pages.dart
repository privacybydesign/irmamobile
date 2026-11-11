part of "glass_sheet.dart";

/// Pages inside one sheet, as the navigation stack of a native iOS sheet.
/// [pages] is the stack, the first at the bottom, each with a key of its own;
/// the last is shown. A new last page slides in from the right over the one
/// under it, which moves 30% of the way left; a removed one slides back out. A horizontal swipe on a subpage takes it back the iOS way: it follows
/// the finger, and past half way or with a flick it calls [onBack], which
/// removes it.
///
/// A [GlassSheetPage] slides only its body: its bar (the titles fade into
/// each other) stays where it is, so the sheet's top
/// does not move between steps. Any other page slides as a whole when it is
/// wrapped in a [GlassSheetPageMotion].
class GlassSheetPages extends StatefulWidget {
  final List<Widget> pages;
  final VoidCallback onBack;

  /// When the first page is under another one, it moves this far left (not
  /// 30%) and is dimmed: a page that a whole flow is pushed onto (Welk
  /// kaartje deel je? under adding a card). Popping back to it takes 300 ms.
  final double? rootShift;

  const GlassSheetPages({
    super.key,
    required this.pages,
    required this.onBack,
    this.rootShift,
  });

  /// How long a page slides in or out.
  static const slideDuration = Duration(milliseconds: 360);

  /// How far the page under a new one moves left, as a fraction of the width.
  static const underShift = 0.3;

  /// Values the pages keep for the next page (e.g. where a progress bar
  /// stood, so the next one fills on from there); null outside the pages.
  static Map<Object, Object?>? memoryOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>()?.memory;

  /// The key of the page that is on top once the pages stop moving (the new
  /// page while it slides in, the one under while the top one slides out);
  /// null outside the pages.
  static ValueListenable<Object?>? comingOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SheetPageRole>()?.coming;

  /// The key of the page around [context]; null outside the pages.
  static Object? pageKeyOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SheetPageRole>()?.pageKey;

  /// Whether the page around [context] is the one on top (or not in pages
  /// at all), not the one under it.
  static bool isTopPage(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetPageRole>()?.top ?? true;

  /// Hands the back swipe on the page around [context] to [swipe] while it
  /// is [GlassSheetInnerSwipe.enabled] (a page with screens of its own, as
  /// adding a document); null hands it back to the sheet.
  static void setInnerSwipe(BuildContext context, GlassSheetInnerSwipe? swipe) {
    final role = context.getInheritedWidgetOfExactType<_SheetPageRole>();
    if (role == null) return;
    if (swipe == null) {
      role.inner.remove(role.pageKey);
    } else {
      role.inner[role.pageKey] = swipe;
    }
  }

  @override
  State<GlassSheetPages> createState() => _GlassSheetPagesState();
}

class _GlassSheetPagesState extends State<GlassSheetPages>
    with SingleTickerProviderStateMixin {
  /// 1 when the top page is fully in, 0 when it is out to the right.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: GlassSheetPages.slideDuration,
    value: 1,
  )..addListener(() => _moving.value = _slide.value < 1);

  /// What is on screen: [GlassSheetPages.pages], plus a page that is sliding
  /// out after it was removed.
  late List<Widget> _shown = widget.pages;

  /// See [GlassSheetPages.memoryOf].
  final _memory = <Object, Object?>{};

  /// See [GlassSheetPages.comingOf].
  late final _coming = ValueNotifier<Object?>(widget.pages.last.key);

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

  /// The pages that take the back swipe themselves, by page key (see
  /// [GlassSheetPages.setInnerSwipe]).
  final _inner = <Object?, GlassSheetInnerSwipe>{};

  /// The page that takes the swipe under way, if one does.
  GlassSheetInnerSwipe? _innerDrag;

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
    _coming.value = widget.pages.last.key;
    // By the top page: a page that comes or goes under it (the PIN staying
    // under "Success", a step's page dropped once it is done) does not move
    // the page on top. A new top page slides in, unless it was under the old
    // one, which then slides out.
    final oldTop = oldWidget.pages.last.key;
    final newTop = widget.pages.last.key;
    final keyed = oldTop != null && newTop != null;
    final sameTop = keyed && oldTop == newTop;
    final back = keyed
        ? !sameTop && oldWidget.pages.any((p) => p.key == newTop)
        : widget.pages.length < oldWidget.pages.length;
    final added = keyed
        ? !sameTop && !back
        : widget.pages.length > oldWidget.pages.length;
    final removed = back;
    if (sameTop && !_swipedOut) {
      // Sliding out still (a page's removal), it slides on over the pages
      // under it as they are now; otherwise they change in place.
      _shown =
          _shown.length > oldWidget.pages.length && _shown.last.key != newTop
          ? [...widget.pages, _shown.last]
          : widget.pages;
    } else if (added) {
      _shown = widget.pages;
      _slide.value = 0;
      _slide.animateTo(1, curve: YiviMotion.ease);
    } else if (removed && !_swipedOut) {
      // Slides the removed page out over the page under it, then drops it.
      _shown = [...widget.pages, oldWidget.pages.last];
      final toRoot = widget.rootShift != null && widget.pages.length == 1;
      _slide
          .animateBack(
            0,
            duration: toRoot ? const Duration(milliseconds: 300) : null,
            curve: toRoot ? YiviMotion.leave : YiviMotion.ease,
          )
          .whenCompleteOrCancel(() {
            if (!mounted) return;
            setState(() => _shown = widget.pages);
            _slide.value = 1;
          });
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
    _coming.dispose();
    _moving.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _dragStart() {
    final inner = _inner[_shown.last.key];
    if (_slide.value == 1 && inner != null && inner.enabled) {
      // Back a screen inside the page, not a page of the sheet.
      _innerDrag = inner..start();
    } else {
      // Takes over from a slide, as on iOS.
      _slide.stop();
    }
    _dragging = true;
  }

  void _dragUpdate(DragUpdateDetails d, double width) {
    final delta = (d.primaryDelta ?? 0) / width;
    final inner = _innerDrag;
    if (inner != null) {
      inner.update(delta);
    } else if (_canSwipe) {
      _slide.value -= delta;
    }
  }

  void _dragEnd(double velocity) {
    _dragging = false;
    final inner = _innerDrag;
    if (inner != null) {
      _innerDrag = null;
      inner.end(velocity);
      return;
    }
    if (!_canSwipe) return;
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

  /// The system back (Android) on a subpage: back a page, as the back
  /// button and the swipe, instead of closing the sheet. Not while another
  /// route is over the sheet, nor on a page that steps back through its own
  /// screens (its [NavigatorPopHandler] gets the back then).
  Future<bool> _systemBack() async {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return false;
    if (widget.pages.length < 2) return false;
    final inner = _inner[widget.pages.last.key];
    if (inner != null && inner.enabled) return false;
    // A page still sliding: the back is used up, the slide goes on.
    if (_moving.value || _dragging) return true;
    widget.onBack();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Only under a Router: the system back reaches the app through it.
    final router = Router.maybeOf(context);
    final pages = _pages(context);
    return router?.backButtonDispatcher == null
        ? pages
        : BackButtonListener(onBackButtonPressed: _systemBack, child: pages);
  }

  Widget _pages(BuildContext context) {
    final top = _shown.last;
    final under = _shown.length > 1 ? _shown[_shown.length - 2] : null;
    // A page with screens of its own takes the swipe also as the only page.
    final swipes = _canSwipe || _inner.containsKey(top.key);
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: swipes ? (_) => _dragStart() : null,
        onHorizontalDragUpdate: swipes
            ? (d) {
                if (_dragging) _dragUpdate(d, constraints.maxWidth);
              }
            : null,
        onHorizontalDragEnd: swipes
            ? (d) {
                if (_dragging) _dragEnd(d.velocity.pixelsPerSecond.dx);
              }
            : null,
        onHorizontalDragCancel: swipes
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
                  shift:
                      !top && widget.rootShift != null && page == _shown.first
                      ? widget.rootShift!
                      : GlassSheetPages.underShift,
                  dims:
                      !top && widget.rootShift != null && page == _shown.first,
                  memory: _memory,
                  coming: _coming,
                  fadeIn: _fadeIn,
                  fadeOut: _fadeOut,
                  chrome: _chrome,
                  held: _held,
                  inner: _inner,
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

  /// How far this page moves left while one slides in over it.
  final double shift;

  /// This page darkens while one slides in over it.
  final bool dims;
  final Map<Object, Object?> memory;

  /// See [GlassSheetPages.comingOf].
  final ValueListenable<Object?> coming;

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

  /// The pages that take the back swipe themselves (see
  /// [GlassSheetPages.setInnerSwipe]).
  final Map<Object?, GlassSheetInnerSwipe> inner;
  final Key? pageKey;

  /// The page this one changes with while [moving]; null otherwise.
  final Key? otherKey;

  const _SheetPageRole({
    required this.top,
    required this.animation,
    required this.moving,
    required this.reduce,
    required this.width,
    this.shift = GlassSheetPages.underShift,
    this.dims = false,
    required this.memory,
    required this.coming,
    required this.fadeIn,
    required this.fadeOut,
    required this.chrome,
    required this.held,
    required this.inner,
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
    // Always the same widgets, whatever the page is doing: only their
    // colour and dim change. A wrapper that came and went (the sheet's
    // colour while sliding in, the dim while under) would rebuild the page
    // from scratch at the end of every slide, restarting what it animates
    // (the card on "Success" dropping in twice) and losing its scroll.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        _Slide(
          animation: animation,
          from: top ? 1 : 0,
          to: top ? 0 : -shift,
          // The top page covers the one under it, which only moves part of
          // the way: it has the sheet's own colour.
          child: _SheetColoured(coloured: top && moving, child: child),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: dims && !top
                ? AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => ColoredBox(
                      color: sheetDim.withValues(
                        alpha: sheetDim.a * animation.value,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  /// How far [slide] has moved this page, as a fraction of [width].
  double get slidOffset {
    if (reduce) return 0;
    final t = animation.value;
    return top ? 1 - t : -t * shift;
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
      shift != old.shift ||
      dims != old.dims ||
      otherKey != old.otherKey;
}

/// What a [GlassSheetPage] has in its bar; [title] is the key of its title
/// widget, so two pages with the same one (the "For {requestor}" pill on
/// every step of adding a card) keep it in place instead of fading it.
typedef _Chrome = ({bool back, bool action, Key? title});

/// [child] on the sheet's colour while [coloured]; see-through otherwise,
/// with the same widgets either way (see [_SheetPageRole.slide]).
class _SheetColoured extends StatelessWidget {
  final bool coloured;
  final Widget child;

  const _SheetColoured({required this.coloured, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: coloured ? YiviPalette.of(context).sheet : const Color(0x00000000),
    child: child,
  );
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
      afterFrame(() {
        if (role.held.contains(otherKey)) setState(() {});
      });
    }
    // Both pages have buttons: the top page's stand in for the other's.
    final Widget shown = otherHeld
        ? _kept(role.top, widget.child)
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
