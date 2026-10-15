import "package:material_ui/material_ui.dart";

import "../../package_name.dart";

/// Colours and text styles of the glass redesign, in a light and a dark
/// variant. New screens read these through [YiviPalette.of] so they follow the
/// app brightness; the older screens still use [IrmaThemeData] directly.
@immutable
class YiviPalette {
  final Brightness brightness;

  /// Page background behind lists and floating glass controls.
  final Color background;

  /// Soft fill for chips, icon squares and grouped cells.
  final Color tint;

  /// Cards, rows and section groups.
  final Color surface;

  /// Background of sheets.
  final Color sheet;

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

  /// Highlight behind the selected tab in the glass tab bar.
  final Color lens;

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

  const YiviPalette._({
    required this.brightness,
    required this.background,
    required this.tint,
    required this.surface,
    required this.sheet,
    required this.text,
    required this.heading,
    required this.secondaryText,
    required this.faint,
    required this.divider,
    required this.outline,
    required this.handle,
    required this.link,
    required this.infoSurface,
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
    glassFill: Color(0x8FFFFFFF),
    glassBorder: Color(0xBFFFFFFF),
    glassHighlight: Color(0xF2FFFFFF),
    glassShadow: Color(0x1A000000),
    glassStrongFill: Color(0xD1FFFFFF),
    dangerFill: Color(0xFFBD1919),
  );

  static const dark = YiviPalette._(
    brightness: Brightness.dark,
    background: Color(0xFF0E1116),
    tint: Color(0xFF1B2530),
    surface: Color(0xFF1A1E25),
    sheet: Color(0xFF13161B),
    text: Color(0xFFF2F2F4),
    heading: Color(0xFFD9D6D4),
    secondaryText: Color(0xFFA3A0A2),
    faint: Color(0xFF6F6C6E),
    divider: Color(0xFF2A2F37),
    outline: Color(0xFF2C3B48),
    handle: Color(0xFF4A4E55),
    link: Color(0xFF8DBBF2),
    infoSurface: Color(0xFF1B2A3A),
    successSurface: Color(0xFF133324),
    successText: Color(0xFF7EDBA4),
    successTint: Color(0xFF10261B),
    successOutline: Color(0xFF1F4A32),
    warningSurface: Color(0xFF33270F),
    warningText: Color(0xFFF2C46B),
    errorSurface: Color(0xFF3A1A1C),
    errorText: Color(0xFFFF9A9A),
    danger: Color(0xFFFF7A7A),
    lens: Color(0x29FFFFFF),
    glassFill: Color(0x8C242830),
    glassBorder: Color(0x24FFFFFF),
    glassHighlight: Color(0x29FFFFFF),
    glassShadow: Color(0x73000000),
    glassStrongFill: Color(0xE01E2229),
    dangerFill: Color(0xFFC42B2B),
  );

  bool get isDark => brightness == Brightness.dark;

  static YiviPalette of(BuildContext context) =>
      forBrightness(Theme.of(context).brightness);

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
