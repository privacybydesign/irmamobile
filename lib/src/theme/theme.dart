import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Primary colors
  final Color primaryBlue = const Color(0xFF4B73FF);
  final Color primaryPurple = const Color(0xFF8278FB);
  final Color primaryBeige = const Color(0xFFFFD2BC);
  final Color primaryDark = const Color(0xFF15222E);
  final Color primaryLight = const Color(0xFFF2F5F8);
  final Color darkPurple = const Color(0xFF362C78);
  final Color disabled = const Color(0xFFE8ECF0);

  // Supplementary colors (for card backgrounds)
  final Color cardRed = const Color(0xFFD44454);
  final Color cardBlue = const Color(0xFF00B1E6);
  final Color cardOrange = const Color(0xFFFFBB58);
  final Color cardGreen = const Color(0xFF2BC194);

  // Support colors (for alerts and feedback on form elements)
  final Color interactionValid = const Color(0xFF079268);
  final Color interactionInvalid = const Color(0xFFD44454);
  final Color interactionAlert = const Color(0xFFF97D08);
  final Color interactionInformation = const Color(0xFF004C92);
  final Color interactionInvalidTransparant = const Color(0x22D44454);
  final Color interactionCompleted = const Color(0xFF8BBEAF);

  final Color notificationSuccess = const Color(0xFF029B17);
  final Color notificationSuccessBg = const Color(0xFFAADACE);
  final Color notificationError = const Color(0xFFC8192C);
  final Color notificationErrorBg = const Color(0xFFEDB6BF);
  final Color notificationWarning = const Color(0xFFDB6E07);
  final Color notificationWarningBg = const Color(0xFFFAD8B6);
  final Color notificationInfo = const Color(0xFF004C92);
  final Color notificationInfoBg = const Color(0xFFB1CDE5);

  // Support colors (qr scanner)
  final Color overlayValid = const Color(0xFF007E4C);
  final Color overlayInvalid = const Color(0xFFC8192C);

  // Link colors
  final Color linkColor = const Color(0xFF004C92);
  final Color linkVisitedColor = const Color(0xFF71808F);

  // Overlay color
  final Color overlay50 = const Color(0xFF3C4B5A);

  // background color
  final Color backgroundBlue = const Color(0xFFDFE6EE);

  // Grayscale colors (used for text, background colors, lines and icons)
  final Color grayscaleWhite = const Color(0xFFFFFFFF);
  final Color grayscale95 = const Color(0xFFF2F5F8);
  final Color grayscale90 = const Color(0xFFE8ECF0);
  final Color grayscale85 = const Color(0xFFE3E9F0);
  final Color grayscale80 = const Color(0xFFB7C2CC);
  final Color grayscale70 = const Color(0xFF999999);
  final Color grayscale60 = const Color(0xFF71808F);
  final Color grayscale50 = const Color(0xFF646464);
  final Color grayscale45 = const Color(0xFF3C4B5A);
  final Color grayscale40 = const Color(0xFF454545);
  final Color grayscale30 = const Color(0xFF2E3035);
  final Color grayscale20 = const Color(0xFF1A1A1A);

  //Fonts
  final String fontFamilyKarla = "Karla";
  final String fontFamilyMontserrat = "Montserrat";
  final String fontFamilyUbuntu = "Ubuntu";
  final String fontFamilySfProText = "SF Pro Text";

  late TextTheme textTheme;
  late ThemeData themeData;
  late TextStyle collapseTextStyle;
  late TextStyle textButtonTextStyle;
  late TextStyle issuerNameTextStyle;
  late TextStyle newCardButtonTextStyle;
  late TextStyle hyperlinkTextStyle;
  late TextStyle hyperlinkVisitedTextStyle;
  late TextStyle boldBody;
  late TextStyle highlightedTextStyle;

  IrmaThemeData() {
    textTheme = TextTheme(
        headline1:
            TextStyle(fontSize: 36.0, fontFamily: fontFamilyUbuntu, fontWeight: FontWeight.w700, color: darkPurple),
        headline2:
            TextStyle(fontSize: 24.0, fontFamily: fontFamilyUbuntu, fontWeight: FontWeight.w700, color: darkPurple),
        headline3:
            TextStyle(fontSize: 18.0, fontFamily: fontFamilyUbuntu, fontWeight: FontWeight.w700, color: grayscale30),
        headline4:
            TextStyle(fontSize: 16.0, fontFamily: fontFamilyUbuntu, fontWeight: FontWeight.w700, color: grayscale40),
        headline5:
            TextStyle(fontSize: 14.0, fontFamily: fontFamilyUbuntu, fontWeight: FontWeight.w500, color: grayscale20),
        bodyText1:
            TextStyle(fontSize: 16.0, fontFamily: fontFamilySfProText, fontWeight: FontWeight.w400, color: grayscale50),
        bodyText2: TextStyle(
            fontSize: 14.0, fontFamily: fontFamilySfProText, fontWeight: FontWeight.w400, color: grayscale70));

    themeData = ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryBlue,
        disabledColor: disabled,
        scaffoldBackgroundColor: primaryLight,
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
        fontFamily: fontFamilyKarla,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          elevation: 0,
          color: grayscale85,
          iconTheme: IconThemeData(
            color: primaryDark,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          toolbarTextStyle: textTheme.bodyText2,
          titleTextStyle: textTheme.headline6,
        ),
        inputDecorationTheme: InputDecorationTheme(
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
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: cardRed));

    collapseTextStyle = TextStyle(
      fontFamily: fontFamilyKarla,
      fontSize: 18.0,
      height: 22.0 / 18.0,
      fontWeight: FontWeight.normal,
      color: grayscale40,
    );

    textButtonTextStyle = TextStyle(
      fontFamily: fontFamilyMontserrat,
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primaryBlue,
    );

    newCardButtonTextStyle = TextStyle(
      fontFamily: fontFamilyMontserrat,
      fontSize: 18.0,
      height: 22.0 / 18.0,
      fontWeight: FontWeight.w500,
      color: grayscale40,
    );

    hyperlinkTextStyle = TextStyle(
      fontFamily: fontFamilyMontserrat,
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.normal,
      color: primaryBlue,
      decoration: TextDecoration.underline,
    );

    hyperlinkVisitedTextStyle = TextStyle(
      fontFamily: fontFamilyMontserrat,
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.normal,
      color: grayscale60,
    );

    boldBody = TextStyle(
      fontFamily: fontFamilyMontserrat,
      fontSize: 16.0,
      height: 24.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primaryDark,
    );

    highlightedTextStyle = TextStyle(
      fontFamily: fontFamilyMontserrat,
      fontSize: 16.0,
      height: 19.0 / 16.0,
      fontWeight: FontWeight.w600,
      color: primaryBlue,
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
