import "package:material_ui/material_ui.dart";

/// Where the floating glass bars sit: the search field at the top of a tab,
/// the tab bar at the bottom, and the buttons of a screen's bottom bar.
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

  /// Distance from the bottom of the screen to the bottom of the lowest
  /// button of a bottom bar, on every screen and sheet: as on native iOS (an
  /// iPhone 17 Pro, iOS 26), 5 pt above the home indicator's inset, else 16.
  /// It reads the device's inset ([MediaQuery.viewPaddingOf]), which a
  /// [SafeArea] or a sheet does not change.
  static double buttonBottom(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return inset > 0 ? inset + 5 : 16;
  }

  /// The padding under the lowest button that puts it at [buttonBottom], less
  /// what a [SafeArea] around it already takes of the inset.
  static double buttonPadding(BuildContext context) {
    final media = MediaQuery.of(context);
    final taken = media.viewPadding.bottom - media.padding.bottom;
    return (buttonBottom(context) - taken).clamp(0.0, double.infinity);
  }
}
