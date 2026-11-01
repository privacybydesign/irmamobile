import "dart:math";

import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../notifications/bloc/notifications_bloc.dart";
import "irma_nav_bar.dart";
import "irma_qr_scan_button.dart";

/// The home screen's navigation, one look on both platforms: the same tabs
/// in the same order, the selected one marked by a short rose line on the
/// bar's edge, and the round Scan QR button at the end. Only the container
/// follows the platform: floating on iOS, docked to the screen's edge on
/// Android ([HomeNavigation.docked]).
abstract final class HomeNavigation {
  /// Docked to the screen's edge (Android, with buttons and with gestures)
  /// rather than floating over the content (iOS).
  static bool docked(BuildContext context) =>
      Theme.of(context).platform != TargetPlatform.iOS;

  /// Whether a docked bar is on screen, at the bottom, with nothing over it:
  /// it is under Android's navigation buttons then, and the solid band
  /// that SystemNavigationBarStyle puts behind them stays away.
  static final bottomBarShown = ValueNotifier(false);

  /// The docked bars on screen now (a bar is built anew when the layout
  /// changes, the old one going as the new one comes).
  static final _shownBy = <Object>{};

  /// Notes whether [bar] is a docked bar on screen, and passes it on once
  /// the frame is done: not while the tree is being built or torn down.
  static void _report(Object bar, {required bool shown}) {
    shown ? _shownBy.add(bar) : _shownBy.remove(bar);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => bottomBarShown.value = _shownBy.isNotEmpty,
    );
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// The selected tab's line: 3 thick, on the bar's edge, square there and
  /// rounded on the inside.
  static const double lineThickness = 3;

  static Duration _slide(BuildContext context) =>
      YiviMotion.duration(context, const Duration(milliseconds: 240));
}

/// The tabs: the label's key, the selected icon and the other one.
const homeTabs = [
  (
    IrmaNavBarTab.data,
    "home.nav_bar.data",
    TabGlyph.icon(Icons.person),
    TabGlyph.icon(Icons.person_outline),
  ),
  (
    IrmaNavBarTab.activity,
    "home.nav_bar.activity",
    TabGlyph.filledHistory,
    TabGlyph.icon(Icons.history),
  ),
  (
    IrmaNavBarTab.notifications,
    "home.nav_bar.notifications",
    TabGlyph.icon(Icons.notifications),
    TabGlyph.icon(Icons.notifications_outlined),
  ),
  // Three lines, not the … of the Data tab's menu.
  (
    IrmaNavBarTab.more,
    "home.nav_bar.more",
    TabGlyph.icon(Icons.menu_rounded),
    TabGlyph.icon(Icons.menu_rounded),
  ),
];

/// A tab's icon: a Material [icon], or a drawn [path] (24 × 24) for one
/// Material lacks.
class TabGlyph {
  final IconData? icon;
  final String? path;

  const TabGlyph.icon(IconData this.icon) : path = null;

  const TabGlyph._path(String this.path) : icon = null;

  /// Activity, selected: the history arrow around a solid clock face with
  /// its hands cut out, as filled as the other selected icons.
  static const filledHistory = TabGlyph._path(
    "M13 3c-4.97 0-9 4.03-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 "
    "3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42C8.27 19.99 "
    "10.51 21 13 21c4.97 0 9-4.03 9-9s-4.03-9-9-9z"
    "M13 6.3a5.7 5.7 0 1 1 0 11.4a5.7 5.7 0 1 1 0-11.4z"
    "M12.1 8.6v4.6l3.75 2.23.62-1.04-3.07-1.83V8.6h-1.3z",
  );

  Widget build(Color color, double size) {
    final path = this.path;
    if (path == null) return Icon(icon, size: size, color: color);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path fill-rule="evenodd" d="$path"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// The tab bar of a phone held upright: on iOS a capsule floating over the
/// content, on Android a bar docked to the bottom, under the system's
/// buttons or gesture handle. The four tabs, a divider, and the Scan QR
/// button at the right end.
class HomeTabBar extends StatefulWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;
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
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: StadiumBorder(side: BorderSide(color: palette.divider)),
          shadows: [
            BoxShadow(
              color: palette.glassShadow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: row,
      );
    }
    final padding = MediaQuery.viewPaddingOf(context);
    return Container(
      height: HomeTabBar.dockedHeight + padding.bottom,
      padding: EdgeInsets.only(
        left: padding.left + 4,
        right:
            padding.right +
            (HomeTabBar.dockedHeight - 1 - HomeScanButton.size) / 2,
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
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;
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

  /// The tab at [place], counted from the left.
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
        final place = _rtl ? _count - 1 - index : index;
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
                            showDot: tab == IrmaNavBarTab.notifications,
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
                                          (_middleOf(
                                                        _rtl
                                                            ? _count - 1 - i
                                                            : i,
                                                      ) -
                                                      x)
                                                  .abs() /
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

/// The navigation of a phone held sideways: a rail with the tabs, a divider
/// and the Scan QR button at its bottom end. On iOS it floats, centred top
/// to bottom; on Android it is docked to the left edge, full height.
class HomeRail extends StatelessWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;
  final bool docked;

  const HomeRail({
    super.key,
    required this.selectedTab,
    required this.onChangeTab,
    required this.docked,
  });

  /// The floating rail's width; the docked one is [dockedWidth] wide, plus
  /// the screen's inset on that side.
  static const double width = 76;
  static const double dockedWidth = 80;

  /// A tab's height.
  static const double tabHeight = 58;

  /// The Scan QR button's size.
  static const double scanButtonSize = HomeScanButton.size;

  /// From the top of the tabs to the bottom of the Scan button, padding
  /// included: what a tip beside the button measures from.
  static const double height = 8 + 4 * tabHeight + 13 + scanButtonSize + 10;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final index = homeTabs.indexWhere((t) => t.$1 == selectedTab);
    final column = SizedBox(
      width: docked ? dockedWidth : width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  for (final (tab, labelKey, activeIcon, icon) in homeTabs)
                    SizedBox(
                      height: tabHeight,
                      child: _Tab(
                        key: Key("nav_button_${tab.name}"),
                        label: FlutterI18n.translate(context, labelKey),
                        icon: tab == selectedTab ? activeIcon : icon,
                        selected: tab == selectedTab,
                        showDot: tab == IrmaNavBarTab.notifications,
                        labelSize: docked ? 12 : 10,
                        onTap: () => onChangeTab(tab),
                      ),
                    ),
                ],
              ),
              AnimatedPositioned(
                duration: HomeNavigation._slide(context),
                curve: YiviMotion.ease,
                left: 0,
                top: tabHeight * index + (tabHeight - 24) / 2,
                width: HomeNavigation.lineThickness,
                height: 24,
                child: const _Line(edge: AxisDirection.left),
              ),
            ],
          ),
          Container(
            width: 32,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: palette.divider,
          ),
          const HomeScanButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
    if (docked) {
      final padding = MediaQuery.paddingOf(context);
      return Container(
        padding: EdgeInsets.only(left: padding.left),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(right: BorderSide(color: palette.divider)),
        ),
        alignment: Alignment.center,
        child: column,
      );
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        // Corners small enough that the edge is straight beside every tab,
        // where the line sits.
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: palette.divider),
        ),
        shadows: [
          BoxShadow(
            color: palette.glassShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: column,
    );
  }
}

/// The navigation of the tablet layout: a sidebar with the logo, the four
/// destinations and a Scan QR button at the bottom. On iOS it floats, with
/// a margin; on Android it is docked to the left edge, full height.
class HomeSidebar extends StatelessWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;
  final bool docked;

  const HomeSidebar({
    super.key,
    required this.selectedTab,
    required this.onChangeTab,
    required this.docked,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              palette.logoAsset,
              height: 36,
              excludeFromSemantics: true,
            ),
          ),
        ),
        for (final (tab, labelKey, activeIcon, icon) in homeTabs)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _SidebarItem(
              key: Key("nav_button_${tab.name}"),
              label: FlutterI18n.translate(context, labelKey),
              icon: tab == selectedTab ? activeIcon : icon,
              selected: tab == selectedTab,
              showUnread: tab == IrmaNavBarTab.notifications,
              onTap: () => onChangeTab(tab),
            ),
          ),
        const Spacer(),
        FancyPillButton(
          key: const Key("nav_button_scanner"),
          label: FlutterI18n.translate(context, "home.nav_bar.scan_qr"),
          leading: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
          ),
          onPressed: () => openQrCodeScanner(context),
        ),
      ],
    );
    if (docked) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          padding.left + 12,
          padding.top + 24,
          12,
          padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(right: BorderSide(color: palette.divider)),
        ),
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(YiviCorners.pane),
          ),
          side: BorderSide(color: palette.divider),
        ),
        shadows: [
          BoxShadow(
            color: palette.glassShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final TabGlyph icon;
  final bool selected;
  final bool showUnread;
  final VoidCallback onTap;

  const _SidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final color = selected ? palette.selectedTab : palette.heading;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    spacing: 12,
                    children: [
                      icon.build(color, 24),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(
                                15,
                                weight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              )
                              .copyWith(color: color),
                        ),
                      ),
                      if (showUnread) const _UnreadCount(),
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    left: 0,
                    top: 12,
                    bottom: 12,
                    width: HomeNavigation.lineThickness,
                    child: _Line(edge: AxisDirection.left),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The number of unread notifications, in a rose pill; nothing without.
class _UnreadCount extends StatelessWidget {
  const _UnreadCount();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unread = state is NotificationsLoaded
            ? state.notifications.where((n) => !n.read).length
            : 0;
        if (unread == 0) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(minWidth: 22),
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: palette.primary,
          ),
          child: Text(
            "$unread",
            style: palette
                .body(12, weight: FontWeight.w700)
                .copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

/// The round Scan QR button in the bar and the rail: the faceted red of the
/// app's primary action ([FancyRoundButton]). No shadow of its own: the bar
/// it sits in has one.
class HomeScanButton extends StatelessWidget {
  const HomeScanButton({super.key = const Key("nav_button_scanner")});

  static const double size = 56;

  @override
  Widget build(BuildContext context) => FancyRoundButton(
    icon: Icons.qr_code_scanner_rounded,
    size: size,
    // As big in its circle as on the scan button before (42 in 72).
    iconSize: size * 0.58,
    label: FlutterI18n.translate(context, "home.nav_bar.scan_qr"),
    onPressed: () => openQrCodeScanner(context),
  );
}

/// A tab's icon, 26 pt; with [showDot] (the bell) a small primary dot at its
/// top right while there are unread notifications.
class TabIcon extends StatelessWidget {
  final TabGlyph icon;
  final Color color;
  final bool showDot;

  const TabIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.showDot,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDot) return icon.build(color, 26);
    final palette = YiviPalette.of(context);
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unread =
            state is NotificationsLoaded && state.hasUnreadNotifications;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon.build(color, 26),
            if (unread)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
