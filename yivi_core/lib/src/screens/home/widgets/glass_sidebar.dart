import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../notifications/bloc/notifications_bloc.dart";
import "glass_tab_bar.dart";
import "irma_nav_bar.dart";
import "irma_qr_scan_button.dart";

/// The navigation of the tablet layout: a glass sidebar with the logo, the
/// four destinations of the tab bar and a Scan QR button.
class GlassSidebar extends StatelessWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;

  const GlassSidebar({
    super.key,
    required this.selectedTab,
    required this.onChangeTab,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(YiviCorners.pane)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                YiviPalette.of(context).logoAsset,
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
      ),
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: selected ? palette.lens : Colors.transparent,
            ),
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
                        .body(15, weight: FontWeight.w600)
                        .copyWith(color: color),
                  ),
                ),
                if (showUnread)
                  BlocBuilder<NotificationsBloc, NotificationsState>(
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
