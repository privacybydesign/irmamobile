import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class IrmaThemeData extends Equatable {
  final spacing = 20.0;

  // Primary colors
  final primaryBlue = const Color(0xFF004C92);
  final primaryDark = const Color(0xFF15222E);
  final primaryLight = const Color(0xFFF2F5F8); // background color

  // Grayscale colors (used for text, background colors, lines and icons)
  final greyscaleWhite = const Color(0xFFFFFFFF);
  final greyscale90 = const Color(0xFFE8ECF0);
  final greyscale80 = const Color(0xFFB7C2CC);
  final greyscale60 = const Color(0xFF71808F);
  final greyscale40 = const Color(0xFF3C4B5A);

  // Supplementary colors (for card backgrounds)
  final cardRed = const Color(0xFFD44454);
  final cardBlue = const Color(0xFF00B1E6);
  final cardOrange = const Color(0xFFFFBB58);
  final cardGreen = const Color(0xFF2BC194);

  // Support colors (for alerts and feedback on form elements)
  final interactionValid = const Color(0xFF079268);
  final interactionInvalid = const Color(0xFFD44454);
  final interactionAlert = const Color(0xFFFFBB58);
  final interactionInformation = const Color(0xFF004C92);

  // Link colors
  final linkColor = const Color(0xFF004C92);
  final linkVisitedColor = const Color(0xFF71808F);

  // Overlay color
  final overlay50 = const Color(0xFF3C4B5A);

  final fontFamilyLarge = "Karla";
  final fontFamilySmall = "Montserrat";

  TextStyle issuerNameTextStyle;
  TextTheme textTheme;
  ThemeData themeData;

  IrmaThemeData() {
    // Additional text styles
    issuerNameTextStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      fontFamily: fontFamilySmall,
      color: greyscaleWhite,
    );

    textTheme = TextTheme(
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

    themeData = ThemeData(
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
        textTheme: textTheme.copyWith(
          body1: textTheme.body1.copyWith(
            color: primaryDark,
          ),
        ),
        iconTheme: IconThemeData(
          color: greyscale40,
        ),
      ),
    );
  }
}

class IrmaTheme extends InheritedWidget {
  final data = IrmaThemeData();

  // IrmaTheme provides the IRMA ThemeData to descendents. Therefore descendents
  // must be wrapped in a Builder.
  IrmaTheme({Key key, WidgetBuilder builder})
      : super(
          key: key,
          child: Builder(builder: builder),
        );

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return (oldWidget as IrmaTheme).data != data;
  }

  static IrmaThemeData of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(IrmaTheme) as IrmaTheme).data;
  }
}
