import "package:material_ui/material_ui.dart";

/// Where the floating glass bars sit: the search field at the top of a tab,
/// the tab bar at the bottom, and the buttons of a screen's bottom bar.
///
/// On iOS they follow the native placement, measured on an iPhone 17 Pro
/// (iOS 26): the top bar's controls start right at the top safe-area edge, and
/// the tab bar ends 21 pt above the bottom of the screen, inside the home
/// indicator's inset. Other platforms keep a margin clear of the system bars,
/// a wider one above Android's back, home and recents buttons.
abstract final class FloatingBarPlacement {
  static bool _ios(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS;

  /// Whether Android shows its back, home and recents buttons at the bottom
  /// of the screen (2- or 3-button navigation), not the gesture handle.
  ///
  /// With gesture navigation the screen's sides take the back gesture, so
  /// they have system gesture insets; with buttons they have none. Sideways
  /// on a phone the buttons go to the side: then the bottom has no inset.
  static bool buttonNavigation(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) return false;
    final media = MediaQuery.of(context);
    final gestures = media.systemGestureInsets;
    return media.viewPadding.bottom > 0 &&
        gestures.left == 0 &&
        gestures.right == 0;
  }

  /// Space between the top safe-area edge and the top of a search field.
  /// Without a status bar (a phone held sideways) 12 from the screen's top.
  static double topGap(BuildContext context) {
    if (MediaQuery.paddingOf(context).top == 0) return 12;
    return _ios(context) ? 0 : 16;
  }

  /// Distance from the bottom of the screen to the bottom of the tab bar.
  static double tabBarBottom(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    if (_ios(context) && inset > 0) return 21;
    if (buttonNavigation(context)) return inset + 12;
    return 16 + (inset > 0 ? inset - 8 : 8);
  }

  /// Distance from the bottom of the screen to the bottom of the lowest
  /// button of a bottom bar, on every screen and sheet: as on native iOS (an
  /// iPhone 17 Pro, iOS 26), 5 pt above the home indicator's inset, else 16.
  /// Above Android's navigation buttons 16, as on Material screens.
  /// It reads the device's inset ([MediaQuery.viewPaddingOf]), which a
  /// [SafeArea] or a sheet does not change.
  ///
  /// A plain [text] button ("Cancel" under the main one) has no surface, so
  /// it sits lower, in the home indicator's area: its 48 pt touch area ends
  /// 24 pt above the bottom, its label about 38 pt above. Never on the
  /// navigation buttons: 8 above them.
  static double buttonBottom(BuildContext context, {bool text = false}) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    if (buttonNavigation(context)) return inset + (text ? 8 : 16);
    if (text) return inset > 0 ? 24 : 8;
    return inset > 0 ? inset + 5 : 16;
  }

  /// The padding under the lowest button that puts it at [buttonBottom], less
  /// what a [SafeArea] around it already takes of the inset.
  static double buttonPadding(BuildContext context, {bool text = false}) {
    final media = MediaQuery.of(context);
    final taken = media.viewPadding.bottom - media.padding.bottom;
    return (buttonBottom(context, text: text) - taken).clamp(
      0.0,
      double.infinity,
    );
  }
}
