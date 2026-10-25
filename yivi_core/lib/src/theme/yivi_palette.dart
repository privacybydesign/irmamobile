import "package:material_ui/material_ui.dart";

import "../../package_name.dart";

/// Colours and text styles of the glass redesign, in a light and a dark
/// variant. New screens read these through [YiviPalette.of] so they follow the
/// app brightness; the older screens still use [IrmaThemeData] directly.
@immutable
class YiviPalette {
  final Brightness brightness;

  /// Page background behind lists and floating glass controls. In the dark
  /// variant black. Under a [YiviPaletteScope] of a sheet: the sheet.
  ///
  /// In the dark variant every layer is lighter than the one it lies on:
  /// [background] < [surface] = [sheet] < [raised], [surface] < [tint],
  /// [raised] < [raisedTint]. A sheet's content gets the raised levels
  /// through [YiviPaletteScope] (see [onSheet]).
  final Color background;

  /// Soft fill for chips, icon squares and grouped cells.
  final Color tint;

  /// Cards, rows and section groups.
  final Color surface;

  /// Background of sheets and of the detail pane next to a list.
  final Color sheet;

  /// Cards, rows and fields on a sheet: in the dark variant one step above
  /// [sheet]. Read it as [surface] under a sheet's [YiviPaletteScope].
  final Color raised;

  /// [tint] on a [raised] card.
  final Color raisedTint;

  /// Whether this is the palette for a sheet's content (dark variant only):
  /// [background] is the sheet, [surface] and [tint] are the raised levels,
  /// and glass that doesn't blur is a solid [surface].
  final bool onSheet;

  /// Body text.
  final Color text;

  /// Headings and neutral icons.
  final Color heading;

  /// Labels and secondary text.
  final Color secondaryText;

  /// Chevrons, dashed outlines.
  final Color faint;

  /// Dividers inside groups.
  final Color divider;

  /// Outlines of chips, segmented controls and source chips.
  final Color outline;

  /// Drag handles.
  final Color handle;

  final Color link;

  /// The soft blue behind an info icon, e.g. a status disc. Not [tint],
  /// which is the page colour in the light theme.
  final Color infoSurface;

  /// Text on a tip box (an [outline]-coloured note), e.g. "Don't hold the
  /// passport directly under a lamp".
  final Color noteText;
  final Color successSurface;
  final Color successText;
  final Color successTint;
  final Color successOutline;
  final Color warningSurface;
  final Color warningText;
  final Color errorSurface;
  final Color errorText;

  /// Text and icons of destructive actions.
  final Color danger;

  /// Highlight behind the selected tab in the glass tab bar and sidebar: a
  /// white lens in the light variant; in the dark variant a lens darker than
  /// the bar, so the selected red stands out against it. The one exception
  /// to "lighter on top": a lighter lens takes the red label below 3:1.
  final Color lens;

  /// Icon and label of the selected tab: the brand red, in the dark variant
  /// a fully saturated, brighter red (about 5.4:1 on its dark lens).
  final Color selectedTab;

  final Color glassFill;
  final Color glassBorder;
  final Color glassHighlight;
  final Color glassShadow;

  /// Fill of dialogs and other glass that carries a lot of text: more opaque
  /// than [glassFill].
  final Color glassStrongFill;

  /// Fill of the button that confirms a destructive action.
  final Color dangerFill;

  /// Brand red, the same in both variants.
  final Color primary = const Color(0xFFBA3354);

  /// The green of a done tick, a finished chip read and the "received"
  /// badge: the same in both themes.
  static const successMark = Color(0xFF00973A);

  const YiviPalette._({
    required this.brightness,
    required this.background,
    required this.tint,
    required this.surface,
    required this.sheet,
    required this.raised,
    required this.raisedTint,
    this.onSheet = false,
    required this.text,
    required this.heading,
    required this.secondaryText,
    required this.faint,
    required this.divider,
    required this.outline,
    required this.handle,
    required this.link,
    required this.infoSurface,
    required this.noteText,
    required this.successSurface,
    required this.successText,
    required this.successTint,
    required this.successOutline,
    required this.warningSurface,
    required this.warningText,
    required this.errorSurface,
    required this.errorText,
    required this.danger,
    required this.lens,
    required this.selectedTab,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassShadow,
    required this.glassStrongFill,
    required this.dangerFill,
  });

  static const light = YiviPalette._(
    brightness: Brightness.light,
    background: Color(0xFFEAF3F9),
    tint: Color(0xFFEAF3F9),
    surface: Color(0xFFFFFFFF),
    sheet: Color(0xFFFAFAFA),
    raised: Color(0xFFFFFFFF),
    raisedTint: Color(0xFFEAF3F9),
    text: Color(0xFF000000),
    heading: Color(0xFF484747),
    // #757375 (neutralDark) is 4.18:1 on the background; this passes AA.
    secondaryText: Color(0xFF6B696B),
    faint: Color(0xFF9F9A9A),
    divider: Color(0xFFEAE5E2),
    outline: Color(0xFFCFE4EF),
    handle: Color(0xFFD7D2CD),
    link: Color(0xFF1D4E89),
    infoSurface: Color(0xFFDCEAF6),
    noteText: Color(0xFF123254),
    successSurface: Color(0xFFD7EFE0),
    successText: Color(0xFF00602A),
    successTint: Color(0xFFE6F5EC),
    successOutline: Color(0xFFBFE5CC),
    warningSurface: Color(0xFFFBEFD8),
    warningText: Color(0xFF7A4F00),
    errorSurface: Color(0xFFF5DBDB),
    errorText: Color(0xFF9E1414),
    danger: Color(0xFFBD1919),
    lens: Color(0xD9FFFFFF),
    selectedTab: Color(0xFFBA3354),
    glassFill: Color(0x8FFFFFFF),
    glassBorder: Color(0xBFFFFFFF),
    glassHighlight: Color(0xF2FFFFFF),
    glassShadow: Color(0x1A000000),
    glassStrongFill: Color(0xD1FFFFFF),
    dangerFill: Color(0xFFBD1919),
  );

  static const dark = YiviPalette._(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    tint: Color(0xFF1B2530),
    surface: Color(0xFF1A1E25),
    sheet: Color(0xFF111419),
    raised: Color(0xFF252A32),
    raisedTint: Color(0xFF2C3744),
    text: Color(0xFFF2F2F4),
    heading: Color(0xFFD9D6D4),
    secondaryText: Color(0xFFA3A0A2),
    faint: Color(0xFF6F6C6E),
    divider: Color(0xFF2A2F37),
    outline: Color(0xFF2C3B48),
    handle: Color(0xFF4A4E55),
    link: Color(0xFF8DBBF2),
    infoSurface: Color(0xFF1B2A3A),
    noteText: Color(0xFFCFE4FF),
    successSurface: Color(0xFF133324),
    successText: Color(0xFF7EDBA4),
    successTint: Color(0xFF10261B),
    successOutline: Color(0xFF1F4A32),
    warningSurface: Color(0xFF33270F),
    warningText: Color(0xFFF2C46B),
    errorSurface: Color(0xFF3A1A1C),
    errorText: Color(0xFFFF9A9A),
    danger: Color(0xFFFF7A7A),
    lens: Color(0x8C000000),
    selectedTab: Color(0xFFFF2D55),
    // See-through, so what passes under it shows, blurred; over black it
    // comes out a little darker than the raised surface.
    glassFill: Color(0x8C3A404B),
    glassBorder: Color(0x24FFFFFF),
    glassHighlight: Color(0x29FFFFFF),
    glassShadow: Color(0x73000000),
    glassStrongFill: Color(0xE02E333C),
    dangerFill: Color(0xFFC42B2B),
  );

  /// [dark] for a sheet's content; see [onSheet].
  static final darkOnSheet = YiviPalette._(
    brightness: Brightness.dark,
    background: dark.sheet,
    tint: dark.raisedTint,
    surface: dark.raised,
    sheet: dark.sheet,
    raised: dark.raised,
    raisedTint: dark.raisedTint,
    onSheet: true,
    text: dark.text,
    heading: dark.heading,
    secondaryText: dark.secondaryText,
    faint: dark.faint,
    divider: dark.divider,
    outline: dark.outline,
    handle: dark.handle,
    link: dark.link,
    infoSurface: dark.infoSurface,
    noteText: dark.noteText,
    successSurface: dark.successSurface,
    successText: dark.successText,
    successTint: dark.successTint,
    successOutline: dark.successOutline,
    warningSurface: dark.warningSurface,
    warningText: dark.warningText,
    errorSurface: dark.errorSurface,
    errorText: dark.errorText,
    danger: dark.danger,
    lens: dark.lens,
    selectedTab: dark.selectedTab,
    glassFill: dark.glassFill,
    glassBorder: dark.glassBorder,
    glassHighlight: dark.glassHighlight,
    glassShadow: dark.glassShadow,
    glassStrongFill: dark.glassStrongFill,
    dangerFill: dark.dangerFill,
  );

  bool get isDark => brightness == Brightness.dark;

  /// The Yivi logo (without margins) for this variant: the dark one has the
  /// colours of the dark iOS app icon.
  String get logoAsset => yiviAsset(
    isDark ? "non-free/logo_no_margin_dark.svg" : "non-free/logo_no_margin.svg",
  );

  /// The palette for [context]: its brightness, and the raised levels on a
  /// sheet ([YiviPaletteScope]).
  static YiviPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark && YiviPaletteScope.onSheetOf(context)) {
      return darkOnSheet;
    }
    return forBrightness(brightness);
  }

  static YiviPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Alexandria, the display face used for headings in the redesign.
  TextStyle display(double size, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        package: packageName,
        fontFamily: "Alexandria",
        fontSize: size,
        height: size <= 16 ? 1.4 : 1.3,
        fontWeight: weight,
        color: heading,
      );

  /// Open Sans, used for body text.
  TextStyle body(double size, {FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: "Open Sans",
        fontSize: size,
        height: size <= 12 ? 16 / 12 : 1.45,
        fontWeight: weight,
        color: text,
      );
}

/// Marks a sheet's content (or the detail pane next to a list): below it,
/// [YiviPalette.of] gives the raised levels, so a card there is lighter than
/// the sheet it lies on. Only the dark variant changes; the light one
/// already has white cards on a lighter-grey sheet.
class YiviPaletteScope extends InheritedWidget {
  const YiviPaletteScope.onSheet({super.key, required super.child});

  static bool onSheetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YiviPaletteScope>() != null;

  @override
  bool updateShouldNotify(YiviPaletteScope oldWidget) => false;
}
