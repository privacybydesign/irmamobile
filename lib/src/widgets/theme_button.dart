import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class ThemeButton extends StatelessWidget {
  ThemeButton({@required this.label, @required this.onPressed, @required this.buttonType, this.textStyle});

  final String label;
  final Function onPressed;
  final buttonType;
  final textStyle;

  @override
  Widget build(BuildContext context) {
    var buttonTheme = {
      'primary': {
        'buttonColor': IrmaTheme.of(context).primaryBlue,
        'buttonTextColor': IrmaTheme.of(context).greyscaleWhite,
        'buttonBorderColor': IrmaTheme.of(context).primaryBlue,
      },
      'secondary': {
        'buttonColor': IrmaTheme.of(context).greyscaleWhite,
        'buttonTextColor': IrmaTheme.of(context).primaryBlue,
        'buttonBorderColor': IrmaTheme.of(context).primaryBlue,
      },
      'link': {
        'buttonColor': Colors.transparent,
        'buttonTextColor': IrmaTheme.of(context).primaryBlue,
        'buttonBorderColor': Colors.transparent,
      },
    };

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
