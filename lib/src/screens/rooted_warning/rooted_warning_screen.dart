import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_bottom_bar.dart';

class RootedWarningScreen extends StatelessWidget {
  final VoidCallback _onAcceptRiskButtonPressed;

  const RootedWarningScreen({
    @required VoidCallback onAcceptRiskButtonPressed,
  }) : _onAcceptRiskButtonPressed = onAcceptRiskButtonPressed;

  @override
  Widget build(BuildContext context) {
    final defaultSpacing = IrmaTheme.of(context).defaultSpacing;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/rooted_warning/rooted_warning.svg',
            excludeFromSemantics: true,
            width: 280,
            height: 245,
          ),
          Container(
            padding: EdgeInsets.only(
              left: defaultSpacing,
              right: defaultSpacing,
              top: 30.0,
            ),
            alignment: Alignment.center,
            child: Text(
              FlutterI18n.translate(context, 'device_rooted_warning.title'),
              style: IrmaTheme.of(context).textTheme.display2,
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              top: defaultSpacing,
              left: defaultSpacing,
              right: defaultSpacing,
            ),
            alignment: Alignment.center,
            child: Text(
              FlutterI18n.translate(context, 'device_rooted_warning.body'),
              style: IrmaTheme.of(context).textTheme.body1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      bottomSheet: IrmaBottomBar(
        primaryButtonLabel: FlutterI18n.translate(context, 'device_rooted_warning.button_accept_risk'),
        onPrimaryPressed: () => _onAcceptRiskButtonPressed(),
      ),
    );
  }
}
