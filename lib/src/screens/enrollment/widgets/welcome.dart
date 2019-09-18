import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/introduction.dart';

class Welcome extends StatelessWidget {
  static const String routeName = 'enrollment/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // prevent overflow when returning for pin input
      resizeToAvoidBottomPadding: false,
      body: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(top: 40),
          child: Column(children: [
            const SizedBox(height: 40),
            SvgPicture.asset('assets/non-free/irma_logo.svg'),
            const SizedBox(height: 20),
            Container(
                constraints: BoxConstraints(maxWidth: 240),
                child: Text(
                  FlutterI18n.translate(context, 'enrollment.welcome.header'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                )),
            const SizedBox(height: 20),
            Container(
              constraints: BoxConstraints(maxWidth: 320),
              child: Text(
                FlutterI18n.translate(context, 'enrollment.welcome.abstract'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
              ),
            ),
            const SizedBox(height: 20),
            FlatButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Introduction()),
                );
              },
              child: Text(
                FlutterI18n.translate(
                    context, 'enrollment.welcome.intro_button'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            RaisedButton(
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChoosePin()),
                );
              },
              child: Text(
                  FlutterI18n.translate(
                      context, 'enrollment.welcome.choose_pin_button'),
                  style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 20),
            RaisedButton(
              color: Colors.white,
              textColor: Colors.black,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
              },
              child: Text(
                  'Not now',
                  style: TextStyle(fontSize: 20)),
            ),
          ])),
    );
  }
}
