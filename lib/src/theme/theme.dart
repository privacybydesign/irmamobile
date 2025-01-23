import 'package:flutter/material.dart';

class IrmaThemeData {
  static const double _spaceBase = 16.0;
  @Deprecated(
      "Move to tinySpacing, smallSpacing, defaultSpacing or largeSpacing, don't use local divisions/multiplications")
  final double spacing = _spaceBase;
  final double tinySpacing = _spaceBase / 4; // 4
  final double smallSpacing = _spaceBase / 2; // 8
  final double defaultSpacing = _spaceBase; // 16
  final double mediumSpacing = _spaceBase * 1.5; // 24
  final double largeSpacing = _spaceBase * 2; // 32
  final double hugeSpacing = _spaceBase * 4; // 64

  // Main colors
  final Color primary = const Color(0xFFBA3354);
  Color get secondary => neutralExtraDark; // Used for buttons and headlines
  final Color tertiary = const Color(0xFFCFE4EF);

  // Background / contrast colors
  Color get backgroundPrimary => light; //Used on scaffolds
  final Color backgroundSecondary = const Color(0xFFFAFAFA);
  Color backgroundTertiary = const Color(0xFFEAF3F9);

  Color get surfacePrimary => light; // Used on cards etc, to contrast with the background
  final Color surfaceSecondary = const Color(0xFFEAF3F9); // Used on cards that are active etc.
  Color surfaceTertiary = const Color(0xffF0DEDE); // Used on cards that expired

// Grey swatch
  final Color dark = Colors.black;
  final Color neutralExtraDark = const Color(0xFF484747);
  final Color neutralDark = const Color(0xFF757375);
  final Color neutral = const Color(0xFF9F9A9A);
  final Color neutralLight = const Color(0xFFD7D2CD);
  final Color neutralExtraLight = const Color(0xFFEAE5E2);
  final Color light = Colors.white;

  // Communicating colors
  final Color error = const Color(0xFFBD1919);
  final Color warning = const Color(0xFFEBA73B);
  final Color success = const Color(0xFF00973A);
  final Color link = const Color(0xFF1D4E89);
  final Color danger = const Color(0xffEABEBE);

  // Fonts
  final String primaryFontFamily = 'Alexandria';
  final String secondaryFontFamily = 'Open Sans';

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
  late final TextStyle boldBody;
  late final TextStyle highlightedTextStyle;

  IrmaThemeData() {
    //Init color scheme
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: light,
      secondary: secondary,
      onSecondary: light,
      error: error,
      onError: light,
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
        color: light,
      ),
    );

    //Init Input Decoration Theme
    final inputDecorationTheme = InputDecorationTheme(
      labelStyle: textTheme.labelSmall,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: secondary,
          width: 2.0,
        ),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: error,
          width: 2.0,
        ),
      ),
      disabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.grey,
        ),
      ),
      errorStyle: textTheme.bodyMedium?.copyWith(color: error),
    );

    //Init App Bar Theme
    final appBarTheme = AppBarTheme(
      elevation: 0,
      color: backgroundPrimary,
      iconTheme: IconThemeData(
        color: dark,
      ),
      toolbarTextStyle: textTheme.bodyMedium,
      titleTextStyle: textTheme.titleLarge,
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
      fontFamily: primaryFontFamily,
      scaffoldBackgroundColor: backgroundPrimary,
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: appBarTheme,
      inputDecorationTheme: inputDecorationTheme,
    );
  }
}

class IrmaTheme extends InheritedWidget {
  final IrmaThemeData data = IrmaThemeData();
  // IrmaTheme provides the IRMA ThemeData to descendents. Therefore descendents
  // must be wrapped in a Builder.
  IrmaTheme({super.key, required WidgetBuilder builder})
      : super(
          child: Builder(builder: builder),
        );

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return (oldWidget as IrmaTheme).data != data;
  }

  static IrmaThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<IrmaTheme>()!.data;
  }
}
