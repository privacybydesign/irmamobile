import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Blocked extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: IrmaTheme.of(context).interactionInvalidTransparant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: IrmaTheme.of(context).hugeSpacing,
          ),
          SvgPicture.asset(
            "assets/error/pin_blocked.svg",
            width: 80,
            height: 80,
          ),
          SizedBox(
            height: IrmaTheme.of(context).largeSpacing,
          ),
          Text(
            FlutterI18n.translate(context, "pin.blocked_title"),
            style: IrmaTheme.of(context).textTheme.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            FlutterI18n.translate(
              context,
              "pin.blocked_body",
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
