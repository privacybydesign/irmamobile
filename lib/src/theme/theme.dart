import 'package:flutter/material.dart';

class IrmaTheme {
  static final spacing = 16.0;
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
  static final supValid = const Color(0xFFD44454);
  static final supInvalid = const Color(0xFFD44454);

  // Link colors
  static final linkColor = const Color(0xFF004C92);
  static final linkVisitedColor = const Color(0xFF71808F);

  // Overlay color
  static final overlay50 = const Color(0xFF3C4B5A);

  // Buttons
  static final primaryButtonTheme = ButtonThemeData(
    buttonColor: primaryBlue,
    shape: StadiumBorder(),
  );

  static final secondaryButtonTheme = ButtonThemeData(
    buttonColor: primaryBlue,
    shape: StadiumBorder(),
  );
}
//
//display4   112.0  thin     0.0      headline1
//display3   56.0   normal   0.0      headline2
//display2   45.0   normal   0.0      headline3
//display1   34.0   normal   0.0      headline4
//headline   24.0   normal   0.0      headline5
//title      20.0   medium   0.0      headline6
//subhead    16.0   normal   0.0      subtitle1
//body2      14.0   medium   0.0      body1
//body1      14.0   normal   0.0      body2
//caption    12.0   normal   0.0      caption
//button     14.0   medium   0.0      button
//subtitle   14.0   medium   0.0      subtitle2
//overline   10.0   normal   0.0      overline

ThemeData irmaTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: IrmaTheme.primaryBlue,
  accentColor: IrmaTheme.supRed,
  scaffoldBackgroundColor: IrmaTheme.primaryLight,
  fontFamily: 'Karla',
  textTheme: TextTheme(
          // display4 is used for extremely large text
          display4: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.w700,
          ),
          // display3 is used for very, very large text
          display3: TextStyle(
            fontSize: 34.0,
            fontWeight: FontWeight.w700,
          ),
          // display2 is used for very large text
          display2: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.w700,
          ),
          // display1 is used for large text
          display1: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.w700,
          ),
          // headline is used for large text in dialogs
          headline: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
            color: IrmaTheme.primaryDark,
          ),
          // title is used for the primary text in app bars and dialogs
          title: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
          ),
          // subhead is used for the primary text in lists
          subhead: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            fontFamily: 'Montserrat',
          ),
          // body1 is the default text style
          body1: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w400,
            fontFamily: 'Montserrat',
            color: IrmaTheme.primaryDark,
          ),
          // body2 is used for emphasizing text that would otherwise be body1
          body2: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            fontFamily: 'Montserrat',
            color: IrmaTheme.primaryDark,
          ),
          // caption is used for auxiliary text associated with images
          caption: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              fontFamily: 'Montserrat'),
          // button is used for text on RaisedButton and FlatButton
          button: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w300,
              fontFamily: 'Montserrat'),
          // subtitle is used for medium emphasis text that's a little smaller than subhead.
          subtitle: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w300,
              fontFamily: 'Montserrat'),
          // is used for the smallest text
          overline: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w300,
              fontFamily: 'Montserrat'))
      .apply(
    bodyColor: IrmaTheme.primaryDark,
  ),
  buttonTheme: IrmaTheme.primaryButtonTheme,
  appBarTheme: AppBarTheme(
    elevation: 0,
    textTheme: TextTheme(
      title: TextStyle(
          color: IrmaTheme.primaryDark,
          fontSize:
              20.0), // Same as title above // TODO find more elegant solution
    ),
    brightness: Brightness.light,
    color: IrmaTheme.primaryLight,
    iconTheme: IconThemeData(
      color: IrmaTheme.gscl40,
    ),
  ),
);
