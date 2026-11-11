part of "home_navigation.dart";

/// The navigation of a phone held sideways: a rail with the tabs, a divider
/// and the Scan QR button at its bottom end. On iOS it floats, centred top
/// to bottom; on Android it is docked to the left edge, full height.
class HomeRail extends StatelessWidget {
  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onChangeTab;
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

  /// From the top of the tabs to the bottom of the Scan button, padding
  /// included: what a tip beside the button measures from.
  static const double height =
      8 + 4 * tabHeight + 13 + HomeScanButton.size + 10;

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
                        showDot: tab == HomeTab.notifications,
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
        decoration: _docked(palette),
        alignment: Alignment.center,
        child: column,
      );
    }
    return DecoratedBox(
      // Corners small enough that the edge is straight beside every tab,
      // where the line sits.
      decoration: _floating(
        palette,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      child: column,
    );
  }
}

/// The navigation of the tablet layout: a sidebar with the logo, the four
/// destinations and a Scan QR button at the bottom. On iOS it floats, with
/// a margin; on Android it is docked to the left edge, full height.
class HomeSidebar extends StatelessWidget {
  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onChangeTab;
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
              showUnread: tab == HomeTab.notifications,
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
        decoration: _docked(palette),
        child: content,
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
      decoration: _floating(
        palette,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.pane)),
        ),
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
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;
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
