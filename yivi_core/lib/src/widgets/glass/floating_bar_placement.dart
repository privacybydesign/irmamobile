import "package:material_ui/material_ui.dart";

/// Where the floating glass bars sit: the search field at the top of a tab
/// and the tab bar at the bottom.
///
/// On iOS they follow the native placement, measured on an iPhone 17 Pro
/// (iOS 26): the top bar's controls start right at the top safe-area edge, and
/// the tab bar ends 21 pt above the bottom of the screen, inside the home
/// indicator's inset. Other platforms keep a margin clear of the system bars.
abstract final class FloatingBarPlacement {
  static bool _ios(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS;

  /// Space between the top safe-area edge and the top of a search field.
  static double topGap(BuildContext context) => _ios(context) ? 0 : 16;

  /// Distance from the bottom of the screen to the bottom of the tab bar.
  static double tabBarBottom(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    if (_ios(context) && inset > 0) return 21;
    return 16 + (inset > 0 ? inset - 8 : 8);
  }
}
