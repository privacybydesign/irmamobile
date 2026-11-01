import "package:material_ui/material_ui.dart";

import "../../package_name.dart";

/// Colours and text styles of the redesign, in a light and a dark
/// variant. New screens read these through [YiviPalette.of] so they follow the
/// app brightness; the older screens still use [IrmaThemeData] directly.
@immutable
class YiviPalette {
  final Brightness brightness;

  /// Page background behind lists and floating controls. In the dark
  /// variant black. Under a [YiviPaletteScope] of a sheet: the sheet.
  ///
  /// In the dark variant every layer is lighter than the one it lies on:
  /// [background] < [surface] = [sheet] < [raised], [surface] < [tint],
  /// [raised] < [raisedTint]. A sheet's content gets the raised levels
  /// through [YiviPaletteScope] ([darkOnSheet]). In the light variant the
  /// sheet is the page colour, white cards on both, so nothing needs a
  /// shadow to stand out; on a sheet [tint] is a step deeper, so a fill
  /// right on the sheet still shows ([lightOnSheet]).
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
  final Color successOutline;
  final Color warningSurface;
  final Color warningText;
  final Color errorSurface;
  final Color errorText;

  /// Text and icons of destructive actions.
  final Color danger;

  /// Icon and label of the selected tab: the brand red, in the dark variant
  /// a fully saturated, brighter red.
  final Color selectedTab;

  /// The shadow of what floats over the page (the tab bar, menus, toasts).
  final Color glassShadow;

  /// Fill of the button that confirms a destructive action.
  final Color dangerFill;

  /// Behind the part of a text that matches a search, with [text] on it.
  /// Dark variant: a deep amber, so light text stays above 4.5:1 on it.
  final Color searchMark;

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
    required this.successOutline,
    required this.warningSurface,
    required this.warningText,
    required this.errorSurface,
    required this.errorText,
    required this.danger,
    required this.selectedTab,
    required this.glassShadow,
    required this.dangerFill,
    required this.searchMark,
  });

  static const light = YiviPalette._(
    brightness: Brightness.light,
    background: Color(0xFFEAF3F9),
    tint: Color(0xFFEAF3F9),
    surface: Color(0xFFFFFFFF),
    sheet: Color(0xFFEAF3F9),
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
    successOutline: Color(0xFFBFE5CC),
    warningSurface: Color(0xFFFBEFD8),
    warningText: Color(0xFF7A4F00),
    errorSurface: Color(0xFFF5DBDB),
    errorText: Color(0xFF9E1414),
    danger: Color(0xFFBD1919),
    selectedTab: Color(0xFFBA3354),
    glassShadow: Color(0x1A000000),
    dangerFill: Color(0xFFBD1919),
    searchMark: Color(0xFFFFE88F),
  );

  // Neutral greys: no blue cast.
  static const dark = YiviPalette._(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    tint: Color(0xFF2C2C2E),
    surface: Color(0xFF1C1C1E),
    sheet: Color(0xFF141416),
    raised: Color(0xFF262628),
    raisedTint: Color(0xFF3A3A3C),
    text: Color(0xFFF2F2F4),
    heading: Color(0xFFD9D6D4),
    secondaryText: Color(0xFFA3A0A2),
    faint: Color(0xFF6F6C6E),
    divider: Color(0xFF38383A),
    outline: Color(0xFF3A3A3C),
    handle: Color(0xFF48484A),
    link: Color(0xFF8DBBF2),
    infoSurface: Color(0xFF1B2A3A),
    noteText: Color(0xFFCFE4FF),
    successSurface: Color(0xFF133324),
    successText: Color(0xFF7EDBA4),
    successOutline: Color(0xFF1F4A32),
    warningSurface: Color(0xFF33270F),
    warningText: Color(0xFFF2C46B),
    errorSurface: Color(0xFF3A1A1C),
    errorText: Color(0xFFFF9A9A),
    danger: Color(0xFFFF7A7A),
    selectedTab: Color(0xFFFF2D55),
    glassShadow: Color(0x73000000),
    dangerFill: Color(0xFFC42B2B),
    searchMark: Color(0xFF6B5300),
  );

  /// [light] for a sheet's content: the sheet as [background], and [tint]
  /// and [raisedTint] a step deeper than the sheet (1.12:1, as white on the
  /// sheet), so a soft fill right on the sheet doesn't vanish into it.
  static final lightOnSheet = light._with(
    background: light.sheet,
    tint: const Color(0xFFD9E7F2),
    raisedTint: const Color(0xFFD9E7F2),
  );

  /// [dark] for a sheet's content: [background] is the sheet, [surface]
  /// and [tint] are the raised levels.
  static final darkOnSheet = dark._with(
    background: dark.sheet,
    tint: dark.raisedTint,
    surface: dark.raised,
  );

  /// This palette with the levels given changed; everything else the same.
  YiviPalette _with({
    Color? background,
    Color? tint,
    Color? surface,
    Color? raisedTint,
  }) => YiviPalette._(
    brightness: brightness,
    background: background ?? this.background,
    tint: tint ?? this.tint,
    surface: surface ?? this.surface,
    sheet: sheet,
    raised: raised,
    raisedTint: raisedTint ?? this.raisedTint,
    text: text,
    heading: heading,
    secondaryText: secondaryText,
    faint: faint,
    divider: divider,
    outline: outline,
    handle: handle,
    link: link,
    infoSurface: infoSurface,
    noteText: noteText,
    successSurface: successSurface,
    successText: successText,
    successOutline: successOutline,
    warningSurface: warningSurface,
    warningText: warningText,
    errorSurface: errorSurface,
    errorText: errorText,
    danger: danger,
    selectedTab: selectedTab,
    glassShadow: glassShadow,
    dangerFill: dangerFill,
    searchMark: searchMark,
  );

  bool get isDark => brightness == Brightness.dark;

  /// Text and icons on a [link] fill (a filter chip, a count badge): white
  /// on the dark blue (8.4:1); on the light blue of dark mode, where white
  /// is only 2:1, a deep navy (8.1:1).
  Color get onLink => isDark ? const Color(0xFF0E2238) : Colors.white;

  /// The Yivi logo (without margins) for this variant: the dark one has the
  /// colours of the dark iOS app icon.
  String get logoAsset => yiviAsset(
    isDark ? "non-free/logo_no_margin_dark.svg" : "non-free/logo_no_margin.svg",
  );

  /// The palette for [context]: its brightness, and the raised levels on a
  /// sheet ([YiviPaletteScope]).
  static YiviPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (YiviPaletteScope.onSheetOf(context)) {
      return brightness == Brightness.dark ? darkOnSheet : lightOnSheet;
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
/// the sheet it lies on. In the light variant only [YiviPalette.tint]
/// changes ([YiviPalette.lightOnSheet]).
class YiviPaletteScope extends InheritedWidget {
  const YiviPaletteScope.onSheet({super.key, required super.child});

  static bool onSheetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<YiviPaletteScope>() != null;

  @override
  bool updateShouldNotify(YiviPaletteScope oldWidget) => false;
}
