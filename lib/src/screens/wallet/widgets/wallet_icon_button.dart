// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/cupertino.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';

class WalletIconButton extends StatelessWidget {
  final IconData iconData;
  final GestureTapCallback onTap;
  final GestureDragDownCallback onVerticalDragDown;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  const WalletIconButton({
    this.iconData,
    this.onTap,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, 'wallet.toggle'),
      child: GestureDetector(
        onTap: onTap,
        onVerticalDragDown: onVerticalDragDown,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            color: IrmaTheme.of(context).grayscale60,
            padding: EdgeInsets.symmetric(
              vertical: IrmaTheme.of(context).smallSpacing,
              horizontal: IrmaTheme.of(context).defaultSpacing,
            ),
            child: Icon(
              iconData,
              color: IrmaTheme.of(context).backgroundBlue,
            ),
          ),
        ),
      ),
    );
  }
}
