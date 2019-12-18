import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaTextButton extends StatelessWidget {
  static const double _defaultMinWidth = 232;

  final String label;
  final double minWidth;
  final VoidCallback onPressed;
  final TextStyle textStyle;

  const IrmaTextButton({
    @required this.label,
    this.onPressed,
    this.textStyle,
    this.minWidth = _defaultMinWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      textTheme: ButtonTextTheme.primary,
      height: 45.0,
      minWidth: minWidth ?? _defaultMinWidth,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: FlatButton(
        onPressed: onPressed,

        textColor: IrmaTheme.of(context).primaryBlue,
        // splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        // highlightColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
        ),
        child: Text(
          FlutterI18n.translate(context, label),
          style: textStyle,
        ),
      ),
    );
  }
}
