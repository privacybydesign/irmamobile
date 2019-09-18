import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:dots_indicator/dots_indicator.dart';

import 'cancel_button.dart';
import 'choose_pin.dart';
import 'welcome.dart';

class Introduction extends StatefulWidget {
  static const String routeName = 'enrollment/introduction';

  @override
  _IntroductionState createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
  int currentIndexPage;
  int pageLength;

  @override
  void initState() {
    currentIndexPage = 0;
    pageLength = 3;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: CancelButton(routeName: Welcome.routeName),
          title: Text('Wat is IRMA?'),
        ),
        body: Stack(
          children: <Widget>[
            PageView(
              children: <Widget>[
                Walkthrougth(
                  imagePath: 'assets/enrollment/load_data.svg',
                  textContent: FlutterI18n.translate(
                      context, 'enrollment.introduction.load_data'),
                ),
                Walkthrougth(
                  imagePath: 'assets/enrollment/use_irma_for_login.svg',
                  textContent: FlutterI18n.translate(
                      context, 'enrollment.introduction.login'),
                ),
                Walkthrougth(
                  imagePath: 'assets/enrollment/use_irma_to_reveal_age.svg',
                  textContent: FlutterI18n.translate(
                      context, 'enrollment.introduction.reveal'),
                ),
              ],
              onPageChanged: (value) {
                setState(() => currentIndexPage = value);
              },
            ),
            Container(
                alignment: Alignment.bottomCenter,
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  new DotsIndicator(
                    dotsCount: pageLength,
                    position: currentIndexPage,
                    decorator: DotsDecorator(
                      color: Colors.grey[400],
                      activeColor: Colors.grey[700],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 30),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(ChoosePin.routeName);
                      },
                      textColor: currentIndexPage == 2 ? Colors.white : null,
                      color: currentIndexPage == 2
                          ? Theme.of(context).primaryColor
                          : null,
                      child: Text(
                          FlutterI18n.translate(
                              context, 'enrollment.welcome.choose_pin_button'),
                          style: TextStyle(fontSize: 20)),
                    ),
                  )
                ]))
          ],
        ));
  }
}

class Walkthrougth extends StatelessWidget {
  final String textContent;
  final String imagePath;

  Walkthrougth({
    Key key,
    @required this.textContent,
    @required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      const SizedBox(height: 20),
      SvgPicture.asset(imagePath),
      const SizedBox(height: 20),
      Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(maxWidth: 280),
        child: Text(
          textContent,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
          textAlign: TextAlign.center,
        ),
      )
    ]);
  }
}
