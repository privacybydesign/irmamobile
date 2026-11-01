import "dart:math";

import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/press_scale.dart";
import "../../notifications/bloc/notifications_bloc.dart";
import "home_tab.dart";
import "open_qr_scanner.dart";

part "home_tab_bar.dart";
part "home_rail.dart";

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
    HomeTab.data,
    "home.nav_bar.data",
    TabGlyph.icon(Icons.person),
    TabGlyph.icon(Icons.person_outline),
  ),
  (
    HomeTab.activity,
    "home.nav_bar.activity",
    TabGlyph.filledHistory,
    TabGlyph.icon(Icons.history),
  ),
  (
    HomeTab.notifications,
    "home.nav_bar.notifications",
    TabGlyph.icon(Icons.notifications),
    TabGlyph.icon(Icons.notifications_outlined),
  ),
  // Three lines, not the … of the Data tab's menu.
  (
    HomeTab.more,
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

/// A floating tab bar, rail or sidebar in [shape]: the surface with a thin
/// edge, lifted off the page by a soft shadow.
ShapeDecoration _floating(YiviPalette palette, OutlinedBorder shape) =>
    ShapeDecoration(
      color: palette.surface,
      shape: shape.copyWith(side: BorderSide(color: palette.divider)),
      shadows: [
        BoxShadow(
          color: palette.glassShadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );

/// A rail or sidebar docked at the left: the surface with a line at its
/// right.
BoxDecoration _docked(YiviPalette palette) => BoxDecoration(
  color: palette.surface,
  border: Border(right: BorderSide(color: palette.divider)),
);
