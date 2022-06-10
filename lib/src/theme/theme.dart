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

  // Colors used in colorscheme
  final Color primaryBlue = const Color(0xFF4B73FF);
  final Color secondaryPurple = const Color(0xFF362C78);

  final Color error = const Color(0xFFBD1919);

  final Color primaryDark = const Color(0xFF15222E);

  final Color lightBlue = const Color(0xFFE9F4FF);
  Color get primaryLight => grayscale95;
  final Color darkPurple = const Color(0xFF362C78);
  Color get disabled => grayscale60;

  // Supplementary colors (for card backgrounds)
  final Color cardRed = const Color(0xFFD44454);
  final Color cardBlue = const Color(0xFF00B1E6);
  final Color cardOrange = const Color(0xFFFFBB58);
  final Color cardGreen = const Color(0xFF2BC194);

  // Support colors (for alerts and feedback on form elements)
  final Color interactionValid = const Color(0xFF079268);
  Color get interactionInvalid => error;
  final Color interactionAlert = const Color(0xFFF97D08);
  Color get interactionInformation => primaryBlue;
  final Color interactionInvalidTransparant = const Color(0x22D44454);
  final Color interactionCompleted = const Color(0xFF8BBEAF);

  final Color notificationSuccess = const Color(0xFF029B17);
  final Color notificationSuccessBg = const Color(0xFFAADACE);
  Color get notificationError => error;
  final Color notificationErrorBg = const Color(0xFFEDB6BF);
  final Color notificationWarning = const Color(0xFFDB6E07);
  final Color notificationWarningBg = const Color(0xFFFAD8B6);
  Color get notificationInfo => primaryBlue;
  final Color notificationInfoBg = const Color(0xFFB1CDE5);

  // Support colors (qr scanner)
  final Color overlayValid = const Color(0xFF007E4C);
  Color get overlayInvalid => error;

  // Link colors
  Color get linkColor => primaryBlue;
  Color get linkVisitedColor => grayscale60;

  // Overlay color
  Color get overlay50 => grayscale40;

  // Background color
  final Color backgroundBlue = Colors.white;

  // Grayscale colors (used for text, background colors, lines and icons)
  final Color grayscaleWhite = const Color(0xFFFFFFFF);
  final Color grayscale95 = const Color(0xFFF2F5F8);
  final Color grayscale90 = const Color(0xFFE8ECF0);
  final Color grayscale85 = const Color(0xFFE3E9F0);
  final Color grayscale80 = const Color(0xFFB7C2CC);
  final Color grayscale60 = const Color(0xFF71808F);
  final Color grayscale40 = const Color(0xFF3C4B5A);

  //Fonts
  final String fontFamilyHeadings = 'Ubuntu';
  final String fontFamilyBody = 'Roboto';

  //TODO: The values below are marked late and have to be initialized in the constructor body.
  //In the future these values should be phased out and be move into ThemeData.colorScheme.

  //Main theme components
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
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: secondaryPurple,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        background: Colors.white,
        onBackground: primaryDark,
        surface: Colors.grey.shade300,
        onSurface: primaryDark);

    //Init Text theme
    textTheme = TextTheme(
      // headline1 is used for extremely large text
      headline1:
          TextStyle(fontSize: 26.0, fontFamily: fontFamilyHeadings, fontWeight: FontWeight.bold, color: primaryDark),
      // headline2 is used for very, very large text
      headline2:
          TextStyle(fontSize: 24.0, fontFamily: fontFamilyHeadings, fontWeight: FontWeight.bold, color: primaryDark),
      // headline3 is used for very large text
      headline3:
          TextStyle(fontSize: 18.0, fontFamily: fontFamilyHeadings, fontWeight: FontWeight.bold, color: primaryDark),
      // headline4 is used for large text
      headline4:
          TextStyle(fontSize: 16.0, fontFamily: fontFamilyHeadings, fontWeight: FontWeight.bold, color: primaryDark),
      // headline5 is used for large text in dialogs
      headline5:
          TextStyle(fontSize: 14.0, fontFamily: fontFamilyHeadings, fontWeight: FontWeight.w500, color: primaryDark),
      // headline6 is used for the primary text in app bars and dialogs
      headline6: TextStyle(
        fontSize: 18.0,
        height: 28.0 / 18.0,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
      ),
      // bodyText1 is used for emphasizing text
      bodyText1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: primaryDark),
      // bodyText2 is the default text style
      bodyText2: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: primaryDark),
      // overline is used for the smallest text
      overline: TextStyle(
        fontFamily: fontFamilyHeadings,
        fontSize: 12.0,
        height: 16.0 / 12.0,
        fontWeight: FontWeight.w600,
        color: grayscale40,
      ),

      // subtitle1 is used for the primary text in lists
      // also used in textfield inputs' text style
      subtitle1: TextStyle(
        fontSize: 16.0,
        height: 22.0 / 18.0,
        fontWeight: FontWeight.normal,
        color: primaryDark,
      ),

      // subtitle2 is used for medium emphasis text that's a little smaller than subhead.
      subtitle2: TextStyle(
        fontSize: 16.0,
        height: 22.0 / 16.0,
        fontWeight: FontWeight.w500,
        color: grayscale40,
      ),

      // caption is used for auxiliary text associated with images
      caption: TextStyle(
        fontSize: 14.0,
        height: 20.0 / 14.0,
        fontWeight: FontWeight.normal,
        color: primaryDark,
      ),
      // button is used for text on ElevatedButton and TextButton
      button: TextStyle(
        fontFamily: fontFamilyHeadings,
        fontSize: 16.0,
        height: 19.0 / 16.0,
        fontWeight: FontWeight.w600,
      ),
    );

    //Init Input Decoration Theme
    final inputDecorationTheme = InputDecorationTheme(
      labelStyle: textTheme.overline,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: grayscale60,
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: primaryBlue,
          width: 2.0,
        ),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: interactionInvalid,
          width: 2.0,
        ),
      ),
      disabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: grayscale80,
        ),
      ),
      errorStyle: textTheme.bodyText2?.copyWith(color: interactionInvalid),
    );

    //Init App Bar Theme
    final appBarTheme = AppBarTheme(
      elevation: 0,
      color: Colors.white,
      iconTheme: IconThemeData(
        color: primaryDark,
      ),
      toolbarTextStyle: textTheme.bodyText2,
      titleTextStyle: textTheme.headline6,
    );

    //Init extra textstyles
    textButtonTextStyle = TextStyle(
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primaryBlue,
    );
    hyperlinkTextStyle = TextStyle(
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.normal,
      color: primaryBlue,
      decoration: TextDecoration.underline,
    );

    boldBody = TextStyle(
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primaryDark,
    );

    highlightedTextStyle = TextStyle(
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primaryBlue,
    );

    // Init final ThemeData composed of all theme components.
    themeData = ThemeData(
      fontFamily: fontFamilyBody,
      scaffoldBackgroundColor: Colors.white,
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
  IrmaTheme({Key? key, required WidgetBuilder builder})
      : super(
          key: key,
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
