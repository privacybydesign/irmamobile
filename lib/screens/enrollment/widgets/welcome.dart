import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'introduction.dart';
import 'choose_pin.dart';

class Welcome extends StatelessWidget {
  static const String routeName = 'enrollment/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
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
                  Navigator.of(context).pushNamed(Introduction.routeName);
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
                  Navigator.of(context).pushNamed(ChoosePin.routeName);
                },
                child: Text(
                    FlutterI18n.translate(
                        context, 'enrollment.welcome.choose_pin_button'),
                    style: TextStyle(fontSize: 20)),
              ),
            ])),
      ),
    );
  }
}
