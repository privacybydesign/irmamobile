import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Welcome extends StatelessWidget {
  static const String routeName = 'enrollment/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // prevent overflow when returning for pin input
      resizeToAvoidBottomPadding: false,
      body: SingleChildScrollView(
        child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: IrmaTheme.spacing * 2),
            child: Column(children: [
              SizedBox(height: IrmaTheme.spacing * 2),
              SvgPicture.asset('assets/non-free/irma_logo.svg'),
              SizedBox(height: IrmaTheme.spacing),
              Container(
                  constraints: BoxConstraints(maxWidth: IrmaTheme.spacing * 16),
                  child: Text(
                    FlutterI18n.translate(context, 'enrollment.welcome.header'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.display1,
                  )),
              SizedBox(height: IrmaTheme.spacing),
              Container(
                constraints: BoxConstraints(maxWidth: IrmaTheme.spacing * 20),
                child: Text(
                  FlutterI18n.translate(context, 'enrollment.welcome.abstract'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.body1,
                ),
              ),
              SizedBox(height: IrmaTheme.spacing),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Introduction.routeName);
                },
                child: Text(
                  FlutterI18n.translate(context, 'enrollment.welcome.intro_button'),
                  style: Theme.of(context).textTheme.button.copyWith(decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: IrmaTheme.spacing),
              RaisedButton(
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  Navigator.of(context).pushNamed(ChoosePin.routeName);
                },
                child: Text(FlutterI18n.translate(context, 'enrollment.welcome.choose_pin_button'),
                    style: Theme.of(context).textTheme.button.copyWith(color: Colors.white)),
              ),
              SizedBox(height: IrmaTheme.spacing),
              RaisedButton(
                color: Colors.white,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
                },
                child: Text('Not now', style: Theme.of(context).textTheme.button),
              ),
            ])),
      ),
    );
  }
}
