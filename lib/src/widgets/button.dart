import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

@Deprecated("Use IrmaButton instead")
class Button extends StatefulWidget {
  final IconData iconData;
  final String accessibleName;
  final Function() onPressed;

  Button({@required this.iconData, @required this.accessibleName, @required this.onPressed});

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> with SingleTickerProviderStateMixin {
  static const _padding = 15.0;

  bool _isBeingPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, widget.accessibleName),
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (tapDownDetails) {
                setState(() {
                  _isBeingPressed = true;
                });
              },
              onPointerUp: (tapUpDetails) {
                setState(() {
                  _isBeingPressed = false;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(right: _padding),
                child: Icon(widget.iconData, color: _isBeingPressed ? Colors.grey[700] : Colors.white),
              ))),
    );
  }
}
