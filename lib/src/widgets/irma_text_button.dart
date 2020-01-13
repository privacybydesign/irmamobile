import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaTextButton extends StatelessWidget {
  final String label;
  final double minWidth;
  final VoidCallback onPressed;
  final TextStyle textStyle;
  final int alpha;

  const IrmaTextButton({
    @required this.label,
    this.onPressed,
    this.textStyle,
    this.minWidth = 232,
    this.alpha = 255
  });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      textTheme: ButtonTextTheme.primary,
      height: 45.0,
      minWidth: minWidth,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: FlatButton(
        onPressed: onPressed,
        textColor: IrmaTheme.of(context).primaryBlue.withAlpha(alpha),
        // splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        // highlightColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(
          FlutterI18n.translate(context, label),
          style: textStyle,
        ),
      ),
    );
  }
}
