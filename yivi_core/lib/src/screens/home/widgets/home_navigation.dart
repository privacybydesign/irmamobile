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

/// The tabs: the selected icon, the other one, and the label's key.
const homeTabs = [
  (IrmaNavBarTab.data, "home.nav_bar.data", Icons.person, Icons.person_outline),
  (
    IrmaNavBarTab.activity,
    "home.nav_bar.activity",
    Icons.history,
    Icons.history,
  ),
  (
    IrmaNavBarTab.notifications,
    "home.nav_bar.notifications",
    Icons.notifications,
    Icons.notifications_outlined,
  ),
  // Three lines, not the … of the Data tab's menu.
  (
    IrmaNavBarTab.more,
    "home.nav_bar.more",
    Icons.menu_rounded,
    Icons.menu_rounded,
  ),
];

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
class _TabRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final index = homeTabs.indexWhere((t) => t.$1 == selectedTab);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / homeTabs.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final place = rtl ? homeTabs.length - 1 - index : index;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                for (final (tab, labelKey, activeIcon, icon) in homeTabs)
                  Expanded(
                    child: _Tab(
                      key: Key("nav_button_${tab.name}"),
                      label: FlutterI18n.translate(context, labelKey),
                      icon: tab == selectedTab ? activeIcon : icon,
                      selected: tab == selectedTab,
                      showDot: tab == IrmaNavBarTab.notifications,
                      labelSize: labelSize,
                      onTap: () => onChangeTab(tab),
                    ),
                  ),
              ],
            ),
            AnimatedPositioned(
              duration: HomeNavigation._slide(context),
              curve: YiviMotion.ease,
              top: 0,
              left: tabWidth * place + (tabWidth - lineWidth) / 2,
              width: lineWidth,
              height: HomeNavigation.lineThickness,
              child: const _Line(edge: AxisDirection.up),
            ),
          ],
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

/// One tab: its icon over its label, rose when selected.
class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool showDot;
  final double labelSize;
  final VoidCallback onTap;

  const _Tab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showDot,
    required this.labelSize,
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
                    .body(
                      labelSize,
                      weight: selected ? FontWeight.w600 : FontWeight.w500,
                    )
                    .copyWith(color: color, height: 14 / labelSize),
              ),
            ],
          ),
        ),
      ),
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
  final IconData icon;
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
                      Icon(icon, size: 24, color: color),
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
  final IconData icon;
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
    if (!showDot) return Icon(icon, size: 26, color: color);
    final palette = YiviPalette.of(context);
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final unread =
            state is NotificationsLoaded && state.hasUnreadNotifications;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 26, color: color),
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
