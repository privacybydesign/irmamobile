import 'package:flutter/material.dart';

class IrmaTheme {
  static final spacing = 20.0;
  // Primary colors
  static final primaryBlue = const Color(0xFF004C92);
  static final primaryDark = const Color(0xFF15222E);
  static final primaryLight = const Color(0xFFF2F5F8); // background color

  // Grayscale colors (used for text, background colors, lines and icons)
  static final greyscaleWhite = const Color(0xFFFFFFFF);
  static final greyscale90 = const Color(0xFFE8ECF0);
  static final greyscale80 = const Color(0xFFB7C2CC);
  static final greyscale60 = const Color(0xFF71808F);
  static final greyscale40 = const Color(0xFF3C4B5A);

  // Supplementary colors (for card backgrounds)
  static final cardRed = const Color(0xFFD44454);
  static final cardBlue = const Color(0xFF00B1E6);
  static final cardOrange = const Color(0xFFFFBB58);
  static final cardGreen = const Color(0xFF2BC194);

  // Support colors (for alerts and feedback on form elements)
  static final interactionValid = const Color(0xFF079268);
  static final interactionInvalid = const Color(0xFFD44454);
  static final interactionAlert = const Color(0xFFFFBB58);
  static final interactionInformation = const Color(0xFF004C92);

  // Link colors
  static final linkColor = const Color(0xFF004C92);
  static final linkVisitedColor = const Color(0xFF71808F);

  // Overlay color
  static final overlay50 = const Color(0xFF3C4B5A);

  static final fontFamilyLarge = "Karla";
  static final fontFamilySmall = "Montserrat";

  // Additional text styles
  static final issuerNameTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamilySmall,
    color: greyscaleWhite,
  );

  static final textTheme = TextTheme(
    // display4 is used for extremely large text
    display4: TextStyle(
      fontFamily: fontFamilyLarge,
      fontSize: 44.0,
      fontWeight: FontWeight.w700,
      color: greyscale40,
    ),
    // display3 is used for very, very large text
    display3: TextStyle(
      fontFamily: fontFamilyLarge,
      fontSize: 38.0,
      fontWeight: FontWeight.w700,
      color: greyscale40,
    ),
    // display2 is used for very large text
    display2: TextStyle(
      fontFamily: fontFamilyLarge,
      fontSize: 32.0,
      fontWeight: FontWeight.w700,
      color: greyscale40,
    ),
    // display1 is used for large text
    display1: TextStyle(
      fontFamily: fontFamilyLarge,
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      color: greyscale40,
    ),
    // headline is used for large text in dialogs
    headline: TextStyle(
      fontFamily: fontFamilyLarge,
      fontSize: 18.0,
      fontWeight: FontWeight.w700,
      color: greyscale40,
    ),
    // title is used for the primary text in app bars and dialogs
    title: TextStyle(
      fontFamily: fontFamilyLarge,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: greyscale40,
    ),
    // subhead is used for the primary text in lists
    subhead: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 16.0,
      fontWeight: FontWeight.w300,
      color: greyscale40,
    ),
    // body1 is the default text style
    body1: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 16.0,
      fontWeight: FontWeight.w300,
      color: primaryDark,
    ),
    // body2 is used for emphasizing text that would otherwise be body1
    body2: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      color: primaryDark,
    ),
    // caption is used for auxiliary text associated with images
    caption: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: primaryDark,
    ),
    // button is used for text on RaisedButton and FlatButton
    button: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: greyscaleWhite,
    ),
    // subtitle is used for medium emphasis text that's a little smaller than subhead.
    subtitle: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: greyscale40,
    ),
    // is used for the smallest text
    overline: TextStyle(
      fontFamily: fontFamilySmall,
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: greyscale60,
    ),
  );

  static final themeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    accentColor: cardRed,
    scaffoldBackgroundColor: primaryLight,
    fontFamily: fontFamilyLarge,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      brightness: Brightness.light,
      color: primaryLight,
      iconTheme: IconThemeData(
        color: greyscale40,
      ),
    ),
  );
}
