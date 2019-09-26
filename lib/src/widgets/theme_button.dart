import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

var buttonTheme = {
  'primary': {
    'buttonColor': IrmaTheme.primaryBlue,
    'buttonTextColor': IrmaTheme.greyscaleWhite,
    'buttonBorderColor': IrmaTheme.primaryBlue,
  },
  'secondary': {
    'buttonColor': IrmaTheme.greyscaleWhite,
    'buttonTextColor': IrmaTheme.primaryBlue,
    'buttonBorderColor': IrmaTheme.primaryBlue,
  },
  'link': {
    'buttonColor': Colors.transparent,
    'buttonTextColor': IrmaTheme.primaryBlue,
    'buttonBorderColor': Colors.transparent,
  },
};

class ThemeButton extends StatelessWidget {
  ThemeButton({@required this.label, @required this.onPressed, @required this.buttonType, this.textStyle});

  final String label;
  final Function onPressed;
  final buttonType;
  final textStyle;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      textTheme: ButtonTextTheme.primary,
      height: 45.0,
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: RaisedButton(
        onPressed: onPressed,
        elevation: 0.0,
        // TODO: Not sure if we want capitalization. Commented for now because
        // they require more complex tests.
        //
        // child: defaultTargetPlatform == TargetPlatform.iOS?
        //     Text(FlutterI18n.translate(context, label), style: textStyle,
        //       )
        //     : Text(
        //         FlutterI18n.translate(context, label).toUpperCase(),
        //         style: textStyle,
        //       ),
        child: Text(
          FlutterI18n.translate(context, label),
          style: textStyle,
        ),
        color: buttonTheme[buttonType]['buttonColor'],
        textColor: buttonTheme[buttonType]['buttonTextColor'],
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0),
            side: BorderSide(color: buttonTheme[buttonType]['buttonBorderColor'], width: 1.0)),
      ),
    );
  }
}
