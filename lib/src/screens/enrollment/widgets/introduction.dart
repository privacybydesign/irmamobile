import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/cancel_button.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/welcome.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';

class Introduction extends StatefulWidget {
  static const String routeName = 'introduction';

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
        title: Text(FlutterI18n.translate(context, 'enrollment.introduction.title')),
      ),
      body: Stack(
        children: <Widget>[
          PageView(
            children: <Widget>[
              Walkthrougth(
                imagePath: 'assets/enrollment/load_data.svg',
                textContent: FlutterI18n.translate(context, 'enrollment.introduction.load_data'),
              ),
              Walkthrougth(
                imagePath: 'assets/enrollment/use_irma_for_login.svg',
                textContent: FlutterI18n.translate(context, 'enrollment.introduction.login'),
              ),
              Walkthrougth(
                imagePath: 'assets/enrollment/use_irma_to_reveal_age.svg',
                textContent: FlutterI18n.translate(context, 'enrollment.introduction.reveal'),
              ),
            ],
            onPageChanged: (value) {
              setState(() => currentIndexPage = value);
            },
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new DotsIndicator(
                  dotsCount: pageLength,
                  position: currentIndexPage,
                  decorator: DotsDecorator(
                    color: Colors.grey[400],
                    activeColor: Colors.grey[700],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.only(top: IrmaTheme.of(context).spacing, bottom: IrmaTheme.of(context).spacing * 2),
                  child: currentIndexPage == 2
                      ? IrmaButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(ChoosePin.routeName);
                          },
                          label: 'enrollment.welcome.choose_pin_button',
                        )
                      : IrmaOutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(ChoosePin.routeName);
                          },
                          label: 'enrollment.welcome.choose_pin_button',
                        ),
                )
              ],
            ),
          )
        ],
      ),
    );
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
      SizedBox(height: IrmaTheme.of(context).spacing),
      SvgPicture.asset(imagePath),
      SizedBox(height: IrmaTheme.of(context).spacing),
      Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).spacing * 18),
        child: Text(
          textContent,
          style: Theme.of(context).textTheme.body1,
          textAlign: TextAlign.center,
        ),
      )
    ]);
  }
}
