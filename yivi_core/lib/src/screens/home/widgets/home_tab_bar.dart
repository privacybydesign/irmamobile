part of "home_navigation.dart";

/// The tab bar of a phone held upright: on iOS a capsule floating over the
/// content, on Android a bar docked to the bottom, under the system's
/// buttons or gesture handle. The four tabs, a divider, and the Scan QR
/// button at the right end.
class HomeTabBar extends StatefulWidget {
  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onChangeTab;
  final bool docked;

  const HomeTabBar({
    super.key,
    required this.selectedTab,
    required this.onChangeTab,
    required this.docked,
  });

  /// The floating capsule's height.
  static const double floatingHeight = 64;

  /// The docked bar's height above the system's inset.
  static const double dockedHeight = 66;

  /// How far above the screen's bottom the bar's top is: what a list leaves
  /// free at its end, and where a tip over the bar sits.
  static double topFromBottom(BuildContext context) =>
      HomeNavigation.docked(context)
      ? dockedHeight + MediaQuery.viewPaddingOf(context).bottom
      : FloatingBarPlacement.tabBarBottom(context) + floatingHeight;

  @override
  State<HomeTabBar> createState() => _HomeTabBarState();
}

class _HomeTabBarState extends State<HomeTabBar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Off once a page covers home, on again as it goes; a menu or a sheet
    // over home leaves it on (a sheet has the band in its own colour).
    final shown = widget.docked && TickerMode.valuesOf(context).enabled;
    HomeNavigation._report(this, shown: shown);
  }

  @override
  void dispose() {
    HomeNavigation._report(this, shown: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tabs = _TabRow(
      selectedTab: widget.selectedTab,
      onChangeTab: widget.onChangeTab,
      labelSize: widget.docked ? 12 : 11,
      lineWidth: widget.docked ? 28 : 24,
    );
    final row = Row(
      children: [
        Expanded(child: tabs),
        const SizedBox(width: 8),
        const HomeScanButton(),
      ],
    );
    if (!widget.docked) {
      return Container(
        height: HomeTabBar.floatingHeight,
        // The Scan button as far from the end as from the top and bottom.
        padding: const EdgeInsetsDirectional.only(
          start: 6,
          end: (HomeTabBar.floatingHeight - HomeScanButton.size) / 2,
        ),
        decoration: _floating(palette, const StadiumBorder()),
        child: row,
      );
    }
    final padding = MediaQuery.viewPaddingOf(context);
    return Container(
      height: HomeTabBar.dockedHeight + padding.bottom,
      // The Scan button 16 in from the edge, as the page's content.
      padding: EdgeInsets.only(
        left: padding.left + 4,
        right: padding.right + 16,
        bottom: padding.bottom,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: row,
    );
  }
}

/// The four tabs side by side, with the selected one's line on the bar's top
/// edge, sliding to the tab picked.
///
/// A finger on the tabs picks the tab it is on when it lets go, so it can
/// slide to another one first. While it is down a lifted lens sits under it:
/// the icon under the lens grows and turns rose, and past the first or last
/// tab the lens stretches after the finger. The finger may leave the bar
/// (up over the page, or over Scan): the tab under it, straight below, still
/// counts, and over Scan that is the last tab.
class _TabRow extends StatefulWidget {
  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onChangeTab;
  final double labelSize;
  final double lineWidth;

  const _TabRow({
    required this.selectedTab,
    required this.onChangeTab,
    required this.labelSize,
    required this.lineWidth,
  });

  @override
  State<_TabRow> createState() => _TabRowState();
}

class _TabRowState extends State<_TabRow> with TickerProviderStateMixin {
  /// How far the finger goes past the first or last tab's middle before the
  /// lens stops stretching, and how much it grows the icon under it.
  static const _maxStretch = 22.0;
  static const _grow = 0.12;

  /// How quickly the lens catches up with the finger.
  static const _catchUp = Duration(milliseconds: 38);

  /// The lens growing in (forward) and settling away (reverse).
  late final _shown = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final _shownCurve = CurvedAnimation(
    parent: _shown,
    curve: YiviMotion.ease,
  );

  /// Where the lens is: eased after the finger once a frame (an animation
  /// restarted on every pointer event would stutter), in the row's own
  /// coordinates, left to right.
  final _x = ValueNotifier(0.0);
  late final _follow = createTicker(_tick);
  double _target = 0;
  Duration? _last;

  int? _pointer;

  /// The place (0 at the left) under the finger, and whether it has been on
  /// another tab than where it went down.
  var _place = 0;
  var _moved = false;

  var _width = 0.0;
  var _height = 0.0;

  @override
  void dispose() {
    _follow.dispose();
    _shownCurve.dispose();
    _shown.dispose();
    _x.dispose();
    super.dispose();
  }

  int get _count => homeTabs.length;

  double get _tabWidth => _width / _count;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// The tab at [place], counted from the left; the other way round, the
  /// place of a tab (it is the same mapping).
  int _tabAt(int place) => _rtl ? _count - 1 - place : place;

  int _placeAt(double dx) =>
      (dx / _tabWidth).floor().clamp(0, _count - 1).toInt();

  double _middleOf(int place) => _tabWidth * (place + 0.5);

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _aim(double dx, {bool jump = false}) {
    // Not clamped to the tabs: past them the lens stretches.
    _target = dx.clamp(-_tabWidth, _width + 2 * _tabWidth).toDouble();
    if (jump || _reduceMotion) {
      _follow.stop();
      _x.value = _target;
    } else if (!_follow.isActive) {
      _last = null;
      _follow.start();
    }
  }

  void _tick(Duration elapsed) {
    final last = _last;
    _last = elapsed;
    final ms = last == null
        ? 16.0
        : min(48.0, (elapsed - last).inMicroseconds / 1000);
    final step = 1 - exp(-ms / _catchUp.inMilliseconds);
    final x = _x.value + (_target - _x.value) * step;
    if ((_target - x).abs() < 0.25) {
      _x.value = _target;
      _follow.stop();
    } else {
      _x.value = x;
    }
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _moved = false;
    _place = _placeAt(event.localPosition.dx);
    _aim(event.localPosition.dx, jump: true);
    if (!_reduceMotion) _shown.forward();
    setState(() {});
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final place = _placeAt(event.localPosition.dx);
    _aim(event.localPosition.dx);
    if (place == _place) return;
    HapticFeedback.selectionClick();
    _moved = true;
    setState(() => _place = place);
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _shown.reverse();
    // The lens settles on the tab picked as it goes.
    _aim(_middleOf(_place));
    setState(() {});
    final tab = homeTabs[_tabAt(_place)].$1;
    // Back on the tab it started on after trying others: nothing, rather
    // than the scroll to the top that a tap on the open tab does.
    if (tab != widget.selectedTab || !_moved) widget.onChangeTab(tab);
  }

  void _lost(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _shown.reverse();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final dark = palette.brightness == Brightness.dark;
    final index = homeTabs.indexWhere((t) => t.$1 == widget.selectedTab);
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        _height = constraints.maxHeight;
        final tabWidth = _tabWidth;
        final place = _tabAt(index);
        final pressing = _pointer != null;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _lost,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shownCurve, _x]),
            builder: (context, _) {
              final shown = _shownCurve.value;
              final raw = _x.value;
              final x = raw.clamp(tabWidth / 2, _width - tabWidth / 2);
              final over = raw - x;
              final stretch =
                  _maxStretch * (1 - 1 / (over.abs() * 0.55 / _maxStretch + 1));
              final squash = 2 * stretch / _maxStretch;
              final lensWidth = tabWidth + 6;
              // While a finger is down the tab under the lens is the one
              // marked; without motion, the one under the finger.
              final marked = !pressing
                  ? index
                  : _tabAt(_reduceMotion ? _place : _placeAt(x.toDouble()));
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (shown > 0)
                    Positioned(
                      left: x - lensWidth / 2 - (over < 0 ? stretch : 0),
                      top: -4 + squash,
                      width: lensWidth + stretch,
                      height: _height + 8 - 2 * squash,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: shown,
                          child: Transform.scale(
                            scale: 0.88 + 0.12 * shown,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: dark ? palette.raisedTint : palette.tint,
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: dark
                                        ? palette.handle
                                        : palette.outline,
                                  ),
                                ),
                                shadows: [
                                  BoxShadow(
                                    color: palette.glassShadow,
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: palette.glassShadow,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      for (final (i, (tab, labelKey, activeIcon, icon))
                          in homeTabs.indexed)
                        Expanded(
                          child: _Tab(
                            key: Key("nav_button_${tab.name}"),
                            label: FlutterI18n.translate(context, labelKey),
                            icon: i == marked ? activeIcon : icon,
                            selected: tab == widget.selectedTab,
                            marked: i == marked,
                            showDot: tab == HomeTab.notifications,
                            labelSize: widget.labelSize,
                            // The icon under the lens grows with how near
                            // the lens's middle is, so it moves with it.
                            scale:
                                1 +
                                _grow *
                                    shown *
                                    max(
                                      0.0,
                                      1 -
                                          (_middleOf(_tabAt(i)) - x).abs() /
                                              tabWidth,
                                    ),
                            handlesTaps: false,
                            onTap: () => widget.onChangeTab(tab),
                          ),
                        ),
                    ],
                  ),
                  AnimatedPositioned(
                    duration: HomeNavigation._slide(context),
                    curve: YiviMotion.ease,
                    top: 0,
                    left: tabWidth * place + (tabWidth - widget.lineWidth) / 2,
                    width: widget.lineWidth,
                    height: HomeNavigation.lineThickness,
                    child: const _Line(edge: AxisDirection.up),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// The selected tab's line, square on the [edge] it sits on.
class _Line extends StatelessWidget {
  final AxisDirection edge;

  const _Line({required this.edge});

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(HomeNavigation.lineThickness);
    return IgnorePointer(
      child: DecoratedBox(
        key: const Key("nav_selected_line"),
        decoration: BoxDecoration(
          color: YiviPalette.of(context).primary,
          borderRadius: switch (edge) {
            AxisDirection.up => const BorderRadius.vertical(bottom: r),
            AxisDirection.left => const BorderRadius.horizontal(right: r),
            _ => BorderRadius.zero,
          },
        ),
      ),
    );
  }
}

/// One tab: its icon over its label, rose when selected (or [marked], while
/// a finger on the tab bar is on it).
class _Tab extends StatelessWidget {
  final String label;
  final TabGlyph icon;
  final bool selected;
  final bool? marked;
  final bool showDot;
  final double labelSize;
  final double scale;

  /// Whether the tab takes taps itself; the tab bar's tabs leave them to
  /// the row ([_TabRow]) and only offer [onTap] to assistive technology.
  final bool handlesTaps;
  final VoidCallback onTap;

  const _Tab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    this.marked,
    required this.showDot,
    required this.labelSize,
    this.scale = 1,
    this.handlesTaps = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final on = marked ?? selected;
    final color = on ? palette.selectedTab : palette.heading;
    final content = Transform.scale(
      scale: scale,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [
          TabIcon(icon: icon, color: color, showDot: showDot),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette
                .body(labelSize, weight: on ? FontWeight.w600 : FontWeight.w500)
                .copyWith(color: color, height: 14 / labelSize),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: handlesTaps ? null : onTap,
      child: handlesTaps
          ? PressScale(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: content,
              ),
            )
          : content,
    );
  }
}
