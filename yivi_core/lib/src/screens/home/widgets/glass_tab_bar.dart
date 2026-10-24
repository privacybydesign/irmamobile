import "dart:math" as math;

import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../notifications/bloc/notifications_bloc.dart";
import "irma_nav_bar.dart";
import "irma_qr_scan_button.dart";

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
  (IrmaNavBarTab.more, "home.nav_bar.more", Icons.more_horiz, Icons.more_horiz),
];

/// The floating glass tab bar, with the round Scan QR action button on its
/// right (like Search in Apple apps).
class GlassTabBar extends StatelessWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;

  const GlassTabBar({
    super.key,
    required this.selectedTab,
    required this.onChangeTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: _Tabs(selectedTab: selectedTab, onChangeTab: onChangeTab),
        ),
        const GlassQrButton(key: Key("nav_button_scanner")),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  final IrmaNavBarTab selectedTab;
  final ValueChanged<IrmaNavBarTab> onChangeTab;

  const _Tabs({required this.selectedTab, required this.onChangeTab});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final selectedIndex = homeTabs.indexWhere((t) => t.$1 == selectedTab);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // As Apple's Liquid Glass tab bar: the selection lens is wider than its
    // tab, reaching a little past it on both sides, with room for that at
    // the ends of the bar.
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: _GlassTabsMetrics.sidePadding,
        vertical: 4,
      ),
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / homeTabs.length;
            const reach = _GlassTabsMetrics.lensReach;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  curve: YiviMotion.overshoot,
                  left: tabWidth * selectedIndex - reach,
                  top: 0,
                  bottom: 0,
                  width: tabWidth + 2 * reach,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: palette.lens,
                      shadows: YiviShadows.lens,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (tab, labelKey, activeIcon, icon) in homeTabs)
                      Expanded(
                        child: _TabButton(
                          key: Key("nav_button_${tab.name}"),
                          label: FlutterI18n.translate(context, labelKey),
                          icon: tab == selectedTab ? activeIcon : icon,
                          selected: tab == selectedTab,
                          showDot: tab == IrmaNavBarTab.notifications,
                          onTap: () => onChangeTab(tab),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

abstract final class _GlassTabsMetrics {
  /// Space at both ends of the bar, so a lens on the first or last tab still
  /// sits inside it.
  static const double sidePadding = 8;

  /// How far the selection lens reaches past its tab on either side.
  static const double lensReach = 6;
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _TabButton({
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

    final iconWidget = TabIcon(icon: icon, color: color, showDot: showDot);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          highlightColor: Colors.transparent,
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              iconWidget,
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette
                    .body(10, weight: FontWeight.w600)
                    .copyWith(color: color, height: 14 / 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The round Scan QR action button, in the faceted Yivi red of today's scan
/// button (`ui/round-btn-bg.svg`) with the same finish as the red pills (a
/// thin light edge along the top, no haze over the red), on the same dark
/// shadow as the glass tab bar.
class GlassQrButton extends StatelessWidget {
  final double size;

  const GlassQrButton({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, "home.nav_bar.scan_qr"),
      excludeSemantics: true,
      child: PressScale(
        scale: 1.08,
        // The same dark shadow as the glass tab bar next to it, so it
        // stands off the cards scrolling behind it.
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            shadows: [
              BoxShadow(
                color: palette.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: palette.glassShadow.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SvgPicture.asset(
                    yiviAsset("ui/round-btn-bg.svg"),
                    fit: BoxFit.cover,
                  ),
                  // No white wash over the red (it looked hazy): a faint rim
                  // and a thin light edge along the top, as on the red pills.
                  const IgnorePointer(
                    child: CustomPaint(painter: _QrButtonEdgePainter()),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      highlightColor: Colors.transparent,
                      customBorder: const CircleBorder(),
                      onTap: () => openQrCodeScanner(context),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: size * 0.47,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The faint rim of [GlassQrButton] and the light edge along its top, which
/// fades out towards the sides.
class _QrButtonEdgePainter extends CustomPainter {
  const _QrButtonEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    // The upper arc, brightest at the top: the light edge of the red pills.
    canvas.drawArc(
      rect,
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = SweepGradient(
          startAngle: math.pi * 1.15,
          endAngle: math.pi * 1.85,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_QrButtonEdgePainter old) => false;
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
