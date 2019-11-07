import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaTextButton extends StatelessWidget {
  final String label;
  final Function onPressed;
  final TextStyle textStyle;

  IrmaTextButton({
    @required this.label,
    this.onPressed,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      textTheme: ButtonTextTheme.primary,
      height: 45.0,
      minWidth: 232,
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: FlatButton(
        child: Text(
          FlutterI18n.translate(context, label),
          style: textStyle,
        ),
        onPressed: onPressed,
        textColor: IrmaTheme.of(context).primaryBlue,
        // splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        // highlightColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(30.0),
        ),
      ),
    );
  }
}
