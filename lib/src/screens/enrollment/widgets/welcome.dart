import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';
import 'package:irmamobile/src/widgets/irma_text_button.dart';

class Welcome extends StatelessWidget {
  static const String routeName = 'welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // prevent overflow when returning for pin input
      resizeToAvoidBottomPadding: false,
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(top: IrmaTheme.of(context).largeSpacing),
          child: Column(
            children: [
              SizedBox(height: IrmaTheme.of(context).largeSpacing),
              SvgPicture.asset(
                'assets/non-free/irma_logo.svg',
                semanticsLabel: FlutterI18n.translate(context, 'accessibility.irma_logo'),
              ),
              SizedBox(height: IrmaTheme.of(context).defaultSpacing),
              Container(
                constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).defaultSpacing * 16),
                child: Text(
                  FlutterI18n.translate(context, 'enrollment.welcome.header'),
                  textAlign: TextAlign.center,
                  style: IrmaTheme.of(context).textTheme.display1,
                ),
              ),
              SizedBox(height: IrmaTheme.of(context).defaultSpacing),
              Container(
                constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).defaultSpacing * 20),
                child: Text(
                  FlutterI18n.translate(context, 'enrollment.welcome.abstract'),
                  textAlign: TextAlign.center,
                  style: IrmaTheme.of(context).textTheme.body1,
                ),
              ),
              SizedBox(height: IrmaTheme.of(context).defaultSpacing),
              IrmaTextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Introduction.routeName);
                },
                label: 'enrollment.welcome.intro_button',
              ),
              SizedBox(height: IrmaTheme.of(context).defaultSpacing),
              IrmaButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(ChoosePin.routeName);
                },
                label: 'enrollment.welcome.choose_pin_button',
              ),
              SizedBox(height: IrmaTheme.of(context).defaultSpacing),
              IrmaOutlinedButton(
                label: 'enrollment.welcome.not_now',
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
