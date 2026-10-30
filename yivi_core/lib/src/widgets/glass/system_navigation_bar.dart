import "dart:ui";

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../../screens/home/widgets/home_navigation.dart";
import "../../theme/yivi_palette.dart";
import "floating_bar_placement.dart";
import "glass_sheet.dart";
import "glass_surface.dart";

/// The system bars for the whole app: the status bar's icons and Android's
/// navigation buttons dark in light mode and light in dark mode, without the
/// grey scrim Android puts behind the buttons, and with the back, home and
/// recents buttons
/// ([FloatingBarPlacement.buttonNavigation]) a frosted band in the page's
/// colour behind them, so content scrolling under them doesn't make them
/// hard to see; in the sheet's colour while a sheet is open, and none over
/// the home screen's docked tab bar, which runs under the buttons.
///
/// Screens that want other buttons (a camera) put their own
/// [AnnotatedRegion] over this one.
class SystemNavigationBarStyle extends StatelessWidget {
  final Widget child;

  const SystemNavigationBarStyle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // The status bar too, so coming back from a screen with its own
        // (a camera's white icons) puts the theme's back.
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: FloatingBarPlacement.buttonNavigation(context)
          ? Stack(
              children: [
                child,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: inset,
                  child: const _ButtonsBand(),
                ),
              ],
            )
          : child,
    );
  }
}

class _ButtonsBand extends StatelessWidget {
  const _ButtonsBand();

  static const double _blur = 12;
  static const double _cover = 0.7;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ValueListenableBuilder<bool>(
      valueListenable: HomeNavigation.bottomBarShown,
      builder: (context, docked, _) => ValueListenableBuilder<int>(
        valueListenable: GlassSheetCover.covering,
        builder: (context, sheets, _) {
          final palette = YiviPalette.of(context);
          // An open sheet reaches the bottom: the band in the sheet's colour.
          // Home's docked tab bar is under the buttons by itself: no band.
          if (sheets == 0 && docked) return const SizedBox.shrink();
          final base = sheets > 0 ? palette.sheet : palette.background;
          final solid =
              MediaQuery.highContrastOf(context) || GlassOpaque.of(context);
          final band = ColoredBox(
            key: const Key("navigation_buttons_band"),
            color: base.withValues(alpha: solid ? 1 : _cover),
            child: const SizedBox.expand(),
          );
          if (solid) return band;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
              child: band,
            ),
          );
        },
      ),
    ),
  );
}
