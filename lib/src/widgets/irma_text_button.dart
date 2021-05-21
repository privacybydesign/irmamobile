import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_themed_button.dart';

class IrmaTextButton extends StatelessWidget {
  final String label;
  final double minWidth;
  final VoidCallback onPressed;
  final TextStyle textStyle;
  final IrmaButtonSize size;

  const IrmaTextButton({
    Key key,
    @required this.label,
    this.onPressed,
    this.textStyle,
    this.size,
    this.minWidth = 232,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      textTheme: ButtonTextTheme.primary,
      height: size?.value ?? 45.0,
      minWidth: minWidth,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: FlatButton(
        onPressed: onPressed,
        textColor: IrmaTheme.of(context).primaryBlue,
        // splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        // highlightColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(
          FlutterI18n.translate(context, label),
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
