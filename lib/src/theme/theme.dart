import 'package:flutter/material.dart';

class IrmaTheme {
  static final spacing = 20.0;
  // Primary colors
  static final primaryBlue = const Color(0xFF004C92);
  static final primaryDark = const Color(0xFF15222E);
  static final primaryLight = const Color(0xFFF2F5F8); // background color

  // Grayscale colors (used for text, background colors, lines and icons)
  static final gsclWhite = const Color(0xFFFFFFFF);
  static final gscl90 = const Color(0xFFE8ECF0);
  static final gscl80 = const Color(0xFFB7C2CC);
  static final gscl60 = const Color(0xFF71808F);
  static final gscl40 = const Color(0xFF3C4B5A);

  // Supplementary colors (for card backgrounds)
  static final supRed = const Color(0xFFD44454);
  static final supBlue = const Color(0xFF00B1E6);
  static final supOrange = const Color(0xFFFFBB58);
  static final supGreen = const Color(0xFF2BC194);

  // Support colors (for alerts and feedback on form elements)
  static final supValid = const Color(0xFF079268);
  static final supInvalid = const Color(0xFFD44454);
  static final supAlert = const Color(0xFFFFBB58);
  static final supInformation = const Color(0xFF004C92);

  // Link colors
  static final linkColor = const Color(0xFF004C92);
  static final linkVisitedColor = const Color(0xFF71808F);

  // Overlay color
  static final overlay50 = const Color(0xFF3C4B5A);

  // Additional text styles
  static final issuerNameTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    fontFamily: 'Montserrat',
    color: IrmaTheme.gsclWhite,
  );
}

ThemeData irmaTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: IrmaTheme.primaryBlue,
  accentColor: IrmaTheme.supRed,
  scaffoldBackgroundColor: IrmaTheme.primaryLight,
  fontFamily: 'Karla',
  textTheme: TextTheme(
    // display4 is used for extremely large text
    display4: TextStyle(
      fontSize: 44.0,
      fontWeight: FontWeight.w700,
      color: IrmaTheme.gscl40,
    ),
    // display3 is used for very, very large text
    display3: TextStyle(
      fontSize: 38.0,
      fontWeight: FontWeight.w700,
      color: IrmaTheme.gscl40,
    ),
    // display2 is used for very large text
    display2: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.w700,
      color: IrmaTheme.gscl40,
    ),
    // display1 is used for large text
    display1: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      color: IrmaTheme.gscl40,
    ),
    // headline is used for large text in dialogs
    headline: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w700,
      color: IrmaTheme.gscl40,
    ),
    // title is used for the primary text in app bars and dialogs
    title: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: IrmaTheme.gscl40,
    ),
    // subhead is used for the primary text in lists
    subhead: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w300,
      fontFamily: 'Montserrat',
      color: IrmaTheme.gscl40,
    ),
    // body1 is the default text style
    body1: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w300,
      fontFamily: 'Montserrat',
      color: IrmaTheme.primaryDark,
    ),
    // body2 is used for emphasizing text that would otherwise be body1
    body2: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      fontFamily: 'Montserrat',
      color: IrmaTheme.primaryDark,
    ),
    // caption is used for auxiliary text associated with images
    caption: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      fontFamily: 'Montserrat',
      color: IrmaTheme.primaryDark,
    ),
    // button is used for text on RaisedButton and FlatButton
    button: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
      color: IrmaTheme.gsclWhite,
    ),
    // subtitle is used for medium emphasis text that's a little smaller than subhead.
    subtitle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      fontFamily: 'Montserrat',
      color: IrmaTheme.gscl40,
    ),
    // is used for the smallest text
    overline: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
      color: IrmaTheme.gscl60,
    ),
  ),
  appBarTheme: AppBarTheme(
    elevation: 0,
    brightness: Brightness.light,
    color: IrmaTheme.primaryLight,
    iconTheme: IconThemeData(
      color: IrmaTheme.gscl40,
    ),
  ),
);
