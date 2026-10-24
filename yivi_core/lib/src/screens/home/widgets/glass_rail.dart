import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../widgets/glass/glass_surface.dart";
import "glass_tab_bar.dart";
import "irma_nav_bar.dart";

/// The navigation of a phone held sideways: a floating glass rail with the
/// tabs' icons, and the round Scan QR button under it.
class GlassRail extends StatelessWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;

  const GlassRail({
    super.key,
    required this.selectedTab,
    required this.onChangeTab,
  });

  /// The rail's width; the content starts 12 to the right of it.
  static const double width = 60;

  /// The round Scan QR button under the tabs.
  static const double scanButtonSize = 56;

  /// The height of the tabs (four 48 buttons, 6 apart, in 6 of glass), the
  /// 12 between, and the Scan button.
  static const double height = 6 + 4 * 48 + 3 * 6 + 6 + 12 + scanButtonSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        GlassSurface(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (final (tab, labelKey, activeIcon, icon) in homeTabs)
                _RailButton(
                  key: Key("nav_button_${tab.name}"),
                  label: FlutterI18n.translate(context, labelKey),
                  icon: tab == selectedTab ? activeIcon : icon,
                  selected: tab == selectedTab,
                  showDot: tab == IrmaNavBarTab.notifications,
                  onTap: () => onChangeTab(tab),
                ),
            ],
          ),
        ),
        const GlassQrButton(
          key: Key("nav_button_scanner"),
          size: scanButtonSize,
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _RailButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final color = selected ? palette.selectedTab : palette.heading;

    // The same unread dot as on the tab bar's bell.
    final iconWidget = TabIcon(icon: icon, color: color, showDot: showDot);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: YiviMotion.duration(
              context,
              const Duration(milliseconds: 200),
            ),
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: selected ? palette.lens : palette.lens.withAlpha(0),
              shadows: selected ? YiviShadows.lens : const [],
            ),
            child: iconWidget,
          ),
        ),
      ),
    );
  }
}
