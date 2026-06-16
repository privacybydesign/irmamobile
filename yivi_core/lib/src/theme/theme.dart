import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "text_styles.dart";
import "yivi_theme_extension.dart";

export "yivi_theme_extension.dart" show YiviThemeExtension, YiviThemeContext;

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

  // Colors still referenced by call sites (helper methods that take an
  // IrmaThemeData parameter, or contexts where Phase 3b's substitution couldn't
  // safely run). The rest live as constructor-local constants below and reach
  // the outside world through colorScheme.X or context.yivi.brand.X.
  Color get secondary => neutralExtraDark;
  Color get backgroundPrimary => light; // scaffolds
  Color get surfacePrimary => light; // cards

  final Color dark = Colors.black;
  final Color neutralExtraDark = const Color(0xFF484747);
  final Color neutralDark = const Color(0xFF757375);
  final Color neutral = const Color(0xFF9F9A9A);
  final Color neutralExtraLight = const Color(0xFFEAE5E2);
  final Color light = Colors.white;

  final Color error = const Color(0xFFBD1919);
  final Color warning = const Color(0xFFEBA73B);
  final Color success = const Color(0xFF00973A);
  final Color link = const Color(0xFF1D4E89);

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

  IrmaThemeData() {
    // Internal palette — consumed only by the ColorScheme + YiviBrandColors
    // setup below. Outside callers reach these values via colorScheme.X or
    // context.yivi.brand.X.
    const primary = Color(0xFFBA3354);
    const tertiary = Color(0xFFCFE4EF);
    const backgroundSecondary = Color(0xFFFAFAFA);
    // backgroundTertiary == surfaceSecondary in the legacy palette — both
    // #EAF3F9. MD3 collapses them onto a single elevation tier.
    const backgroundTertiary = Color(0xFFEAF3F9);
    const surfaceTertiary = Color(0xffF0DEDE);
    const neutralLight = Color(0xFFD7D2CD);
    const errorSurface = Color(0xFFF5DBDB);
    const successSurface = Color(0xFFD7EFE0);
    const danger = Color(0xffEABEBE);

    //Init color scheme — MD3 slots mapped from Yivi brand colors. See
    // plan-theming-architecture.md §4 Phase 3 for the mapping rationale.
    // Slots without a clear Yivi mapping (primaryContainer, secondaryContainer,
    // tertiaryContainer) are left to Flutter's defaults until Phase 6 picks
    // them up alongside the dark scheme.
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: light,
      secondary: secondary,
      onSecondary: light,
      tertiary: tertiary,
      onTertiary: dark,
      error: error,
      onError: light,
      errorContainer: errorSurface,
      onErrorContainer: dark,
      surface: surfacePrimary,
      onSurface: dark,
      onSurfaceVariant: neutralExtraDark,
      surfaceContainerLow: backgroundSecondary,
      surfaceContainerHigh: backgroundTertiary,
      surfaceContainerHighest: surfaceTertiary,
      outline: neutralDark,
      outlineVariant: neutralLight,
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
      bodySmall: TextStyle(
        fontFamily: secondaryFontFamily,
        fontSize: 14.0,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: neutralExtraDark,
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
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: secondary, width: 2.0),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: error, width: 2.0),
      ),
      disabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      errorStyle: textTheme.bodyMedium?.copyWith(color: error),
    );

    //Init App Bar Theme
    final appBarTheme = AppBarTheme(
      backgroundColor: light,
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: dark),
      toolbarTextStyle: textTheme.bodyMedium,
      titleTextStyle: textTheme.displaySmall?.copyWith(color: dark),
      systemOverlayStyle: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
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
      color: light,
      letterSpacing: 2,
    );

    // Domain-named text style groups, exposed via Theme.of(context).extension
    // (context.yivi.*). Built after textTheme and legacy named styles since
    // some groups derive from them.
    final yiviExtension = YiviThemeExtension(
      credential: YiviCredentialStyles.fromTheme(this),
      activity: YiviActivityStyles.fromTheme(this),
      pin: YiviPinStyles.fromTheme(this),
      verification: YiviVerificationStyles.fromTheme(this),
      nfc: YiviNfcStyles.fromTheme(this),
      form: YiviFormStyles.fromTheme(this),
      indicator: YiviIndicatorStyles.fromTheme(this),
      card: YiviCardStyles.fromTheme(this),
      button: YiviButtonStyles.fromTheme(this),
      section: YiviSectionStyles.fromTheme(this),
      requestor: YiviRequestorStyles.fromTheme(this),
      bottomSheet: YiviBottomSheetStyles.fromTheme(this),
      misc: YiviMiscStyles.fromTheme(this),
      brand: YiviBrandColors(
        success: success,
        successSurface: successSurface,
        warning: warning,
        link: link,
        danger: danger,
        neutral: neutral,
        neutralExtraLight: neutralExtraLight,
      ),
      tinySpacing: tinySpacing,
      smallSpacing: smallSpacing,
      defaultSpacing: defaultSpacing,
      mediumSpacing: mediumSpacing,
      largeSpacing: largeSpacing,
      hugeSpacing: hugeSpacing,
      screenPadding: screenPadding,
      borderRadius: borderRadius,
      textButtonTextStyle: textButtonTextStyle,
      hyperlinkTextStyle: hyperlinkTextStyle,
      mrzLabel: mrzLabel,
      primaryFontFamily: primaryFontFamily,
      secondaryFontFamily: secondaryFontFamily,
    );

    // Toast / snackbar default — neutral dark-grey background, light text.
    // Call sites should not override these unless the toast needs to carry a
    // different status (e.g. an error toast, when we have one).
    final snackBarTheme = SnackBarThemeData(
      backgroundColor: secondary,
      contentTextStyle: textTheme.bodySmall!.copyWith(color: light),
      behavior: SnackBarBehavior.floating,
    );

    // Dialog default — surface-coloured card, large elevation, rounded
    // corners. Title and content styles are picked up by IrmaDialog and by
    // any future AlertDialog/SimpleDialog call site.
    final dialogTheme = DialogThemeData(
      backgroundColor: surfacePrimary,
      elevation: 24.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(smallSpacing),
      ),
      titleTextStyle: textTheme.displaySmall,
      contentTextStyle: textTheme.bodyMedium,
    );

    // Init final ThemeData composed of all theme components.
    themeData = ThemeData(
      fontFamily: primaryFontFamily,
      scaffoldBackgroundColor: backgroundPrimary,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: appBarTheme,
      inputDecorationTheme: inputDecorationTheme,
      snackBarTheme: snackBarTheme,
      dialogTheme: dialogTheme,
      extensions: [yiviExtension],
    );
  }
}
