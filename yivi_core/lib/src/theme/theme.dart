import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "page_transitions.dart";

class IrmaThemeData {
  static const double _spaceBase = 16.0;
  @Deprecated(
    "Move to tinySpacing, smallSpacing, defaultSpacing or largeSpacing, don't use local divisions/multiplications",
  )
  final double spacing = _spaceBase;
  final double tinySpacing = _spaceBase / 4; // 4
  final double smallSpacing = _spaceBase / 2; // 8
  final double defaultSpacing = _spaceBase; // 16
  final double mediumSpacing = _spaceBase * 1.5; // 24
  final double largeSpacing = _spaceBase * 2; // 32
  final double hugeSpacing = _spaceBase * 4; // 64

  /// Light or dark. The colour fields below keep their names in both
  /// variants and mean the same role (`light` is the plain surface behind
  /// content, `dark` the plain text colour), so screens built on them follow
  /// the app brightness without changes. Text and icons on a coloured fill
  /// (primary buttons, badges, camera overlays) use [onPrimary], which is
  /// white in both.
  final Brightness brightness;
  bool get isDark => brightness == Brightness.dark;

  // Main colors
  final Color primary = const Color(0xFFBA3354);
  Color get secondary => neutralExtraDark; // Used for buttons and headlines
  final Color tertiary;

  /// Text and icons on [primary] and other coloured fills.
  final Color onPrimary = Colors.white;

  // Background / contrast colors
  final Color backgroundPrimary; // Used on scaffolds
  final Color backgroundSecondary;
  final Color backgroundTertiary;

  Color get surfacePrimary =>
      light; // Used on cards etc, to contrast with the background
  final Color surfaceSecondary; // Used on cards that are active etc.
  final Color surfaceTertiary; // Used on cards that expired

  // Grey swatch, from the text colour ([dark]) to the surface ([light]).
  final Color dark;
  final Color neutralExtraDark;
  final Color neutralDark;
  final Color neutral;
  final Color neutralLight;
  final Color neutralExtraLight;
  final Color light;

  // Communicating colors
  final Color error;
  final Color errorSurface;
  final Color warning;
  final Color success;
  final Color successSurface;
  final Color link;
  final Color danger;

  // Fonts
  final String primaryFontFamily = "Open Sans";
  final String secondaryFontFamily = "Open Sans";

  // Borders
  final BorderRadius borderRadius = BorderRadius.circular(8);

  //TODO: The values below are marked late and have to be initialized in the constructor body.
  //In the future these values should be phased out and be move into ThemeData.colorScheme.

  // Spacing etc.
  late final double screenPadding;

  // Main theme components
  late final TextTheme textTheme;
  late final ThemeData themeData;

  // Other textstyles that cannot be included in TextTheme
  late final TextStyle textButtonTextStyle;
  late final TextStyle hyperlinkTextStyle;
  late final TextStyle mrzLabel;
  late final TextStyle boldBody;
  late final TextStyle highlightedTextStyle;

  // A heading above body text, on screens that have no app bar title for it.
  TextStyle? get bodyHeading => textTheme.bodyLarge?.copyWith(fontSize: 20);

  /// The light theme. [IrmaThemeData.dark] has the same fields with the
  /// colours of the dark palette of the redesign.
  IrmaThemeData() : this._(Brightness.light);

  IrmaThemeData.dark() : this._(Brightness.dark);

  IrmaThemeData._(this.brightness)
    : tertiary = _pick(brightness, 0xFFCFE4EF, 0xFF2C3B48),
      backgroundPrimary = _pick(brightness, 0xFFFFFFFF, 0xFF0E1116),
      backgroundSecondary = _pick(brightness, 0xFFFAFAFA, 0xFF13161B),
      backgroundTertiary = _pick(brightness, 0xFFEAF3F9, 0xFF0E1116),
      surfaceSecondary = _pick(brightness, 0xFFEAF3F9, 0xFF1B2530),
      surfaceTertiary = _pick(brightness, 0xFFF0DEDE, 0xFF3A1A1C),
      dark = _pick(brightness, 0xFF000000, 0xFFF2F2F4),
      neutralExtraDark = _pick(brightness, 0xFF484747, 0xFFD9D6D4),
      neutralDark = _pick(brightness, 0xFF757375, 0xFFA3A0A2),
      neutral = _pick(brightness, 0xFF9F9A9A, 0xFF6F6C6E),
      neutralLight = _pick(brightness, 0xFFD7D2CD, 0xFF4A4E55),
      neutralExtraLight = _pick(brightness, 0xFFEAE5E2, 0xFF2A2F37),
      light = _pick(brightness, 0xFFFFFFFF, 0xFF1A1E25),
      error = _pick(brightness, 0xFFBD1919, 0xFFFF7A7A),
      errorSurface = _pick(brightness, 0xFFF5DBDB, 0xFF3A1A1C),
      warning = _pick(brightness, 0xFFEBA73B, 0xFFF2C46B),
      success = _pick(brightness, 0xFF00973A, 0xFF3FBF74),
      successSurface = _pick(brightness, 0xFFD7EFE0, 0xFF133324),
      link = _pick(brightness, 0xFF1D4E89, 0xFF8DBBF2),
      danger = _pick(brightness, 0xFFEABEBE, 0xFF5A2A2E) {
    //Init color scheme
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: light,
      error: error,
      onError: onPrimary,
      surface: surfacePrimary,
      onSurface: dark,
    );

    //Init spacing
    screenPadding = defaultSpacing;

    //Init Text theme
    textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 26,
        height: 36 / 26,
        fontWeight: FontWeight.w700,
        color: neutralExtraDark,
      ),
      displayMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
        color: neutralExtraDark,
      ),
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 18,
        height: 36 / 18,
        fontWeight: FontWeight.w600,
        color: neutralExtraDark,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16.0,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: neutralExtraDark,
      ),
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16.0,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: neutralExtraDark,
      ),
      titleLarge: TextStyle(
        fontSize: 10,
        height: 16 / 10,
        fontWeight: FontWeight.w500,
        color: neutralExtraDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: secondaryFontFamily,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: dark,
      ),
      bodyMedium: TextStyle(
        fontFamily: secondaryFontFamily,
        fontSize: 16.0,
        height: 24.0 / 16.0,
        fontWeight: FontWeight.w400,
        color: dark,
      ),
      labelSmall: TextStyle(
        fontSize: 12.0,
        height: 16.0 / 12.0,
        fontWeight: FontWeight.w600,
        color: dark,
      ),
      titleMedium: TextStyle(
        fontSize: 16.0,
        height: 22.0 / 18.0,
        fontWeight: FontWeight.normal,
        color: dark,
      ),
      titleSmall: TextStyle(
        fontSize: 16.0,
        height: 22.0 / 16.0,
        fontWeight: FontWeight.w500,
        color: dark,
      ),
      bodySmall: TextStyle(
        fontSize: 14.0,
        height: 24.0 / 14.0,
        fontWeight: FontWeight.normal,
        color: dark,
      ),
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w700,
        color: onPrimary,
      ),
    );

    //Init Input Decoration Theme
    final inputDecorationTheme = InputDecorationTheme(
      labelStyle: textTheme.labelSmall,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: neutral),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: secondary, width: 2.0),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: error, width: 2.0),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: neutral),
      ),
      errorStyle: textTheme.bodyMedium?.copyWith(color: error),
    );

    //Init App Bar Theme
    final appBarTheme = AppBarTheme(
      elevation: 0,
      iconTheme: IconThemeData(color: dark),
      toolbarTextStyle: textTheme.bodyMedium,
      titleTextStyle: textTheme.titleLarge,
      // Android 15+ ignores bar colors under enforced edge-to-edge; icon
      // brightness is what stays readable.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness, // iOS: the background brightness
        systemNavigationBarColor: backgroundPrimary,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    //Init extra textstyles
    textButtonTextStyle = TextStyle(
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: secondary,
    );
    hyperlinkTextStyle = TextStyle(
      fontFamily: secondaryFontFamily,
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.w700,
      color: link,
      decoration: TextDecoration.underline,
    );

    mrzLabel = TextStyle(
      fontFamily: "monospace",
      fontSize: 14,
      color: onPrimary,
      letterSpacing: 2,
    );

    boldBody = TextStyle(
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: dark,
    );

    highlightedTextStyle = TextStyle(
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primary,
    );

    // Init final ThemeData composed of all theme components.
    themeData = ThemeData(
      brightness: brightness,
      fontFamily: primaryFontFamily,
      scaffoldBackgroundColor: backgroundPrimary,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: appBarTheme,
      inputDecorationTheme: inputDecorationTheme,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      pageTransitionsTheme: yiviPageTransitionsTheme,
    );
  }
}

class IrmaTheme extends InheritedWidget {
  final IrmaThemeData data = IrmaThemeData();
  final IrmaThemeData darkData = IrmaThemeData.dark();

  // IrmaTheme provides the IRMA ThemeData to descendents. Therefore descendents
  // must be wrapped in a Builder.
  IrmaTheme({super.key, required WidgetBuilder builder})
    : super(child: Builder(builder: builder));

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return (oldWidget as IrmaTheme).data != data;
  }

  /// The variant matching the brightness of the nearest [Theme]: dark below a
  /// MaterialApp in dark mode, light everywhere else (including above the
  /// MaterialApp, where the app picks its `theme` and `darkTheme`).
  static IrmaThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<IrmaTheme>()!;
    return Theme.of(context).brightness == Brightness.dark
        ? theme.darkData
        : theme.data;
  }

  /// Both variants, for the MaterialApp's `theme` and `darkTheme`.
  static IrmaTheme variantsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IrmaTheme>()!;
}

Color _pick(Brightness brightness, int light, int dark) =>
    Color(brightness == Brightness.dark ? dark : light);
