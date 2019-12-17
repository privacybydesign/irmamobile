import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/choose_pin.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_button.dart';

class Introduction extends StatefulWidget {
  static const String routeName = 'introduction';

  @override
  _IntroductionState createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
  int currentIndexPage;
  int pageLength;

  final _controller = PageController(
    initialPage: 0,
  );

  @override
  void initState() {
    currentIndexPage = 0;
    pageLength = 3;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        scrollDirection: Axis.vertical,
        onPageChanged: (value) {
          setState(() => currentIndexPage = value);
        },
        children: <Widget>[
          Walkthrough(
            image: SvgPicture.asset('assets/enrollment/introduction_screen1.svg', width: 280, height: 245),
            titleContent: FlutterI18n.translate(context, 'enrollment.introduction.screen1.title'),
            textContent: FlutterI18n.translate(context, 'enrollment.introduction.screen1.text'),
            onNextScreen: () => _controller.nextPage(curve: Curves.ease, duration: Duration(milliseconds: 800)),
          ),
          Walkthrough(
            image: SvgPicture.asset('assets/enrollment/introduction_screen2.svg', width: 280, height: 231),
            titleContent: FlutterI18n.translate(context, 'enrollment.introduction.screen2.title'),
            textContent: FlutterI18n.translate(context, 'enrollment.introduction.screen2.text'),
            onNextScreen: () => _controller.nextPage(curve: Curves.ease, duration: Duration(milliseconds: 800)),
          ),
          Walkthrough(
            image: SvgPicture.asset('assets/enrollment/introduction_screen3.svg', width: 341, height: 247),
            titleContent: FlutterI18n.translate(context, 'enrollment.introduction.screen3.title'),
            textContent: FlutterI18n.translate(context, 'enrollment.introduction.screen3.text'),
            onNextScreen: () => {},
            onPressButton: () => Navigator.of(context).pushReplacementNamed(ChoosePin.routeName),
            finalScreen: true,
          ),
        ],
      ),
    );
  }
}

class Walkthrough extends StatelessWidget {
  final String titleContent;
  final String textContent;
  final SvgPicture image;
  final bool finalScreen;
  final void Function() onNextScreen;
  final void Function() onPressButton;

  const Walkthrough({
    Key key,
    @required this.titleContent,
    @required this.textContent,
    @required this.image,
    @required this.onNextScreen,
    this.onPressButton,
    this.finalScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(children: [
          SizedBox(height: IrmaTheme.of(context).spacing * 5),
          image,
          SizedBox(height: IrmaTheme.of(context).spacing * 3),
          Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).spacing * 16),
            child: Text(
              titleContent,
              style: IrmaTheme.of(context).textTheme.display2,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: IrmaTheme.of(context).defaultSpacing),
          Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(maxWidth: IrmaTheme.of(context).spacing * 16),
            child: Text(
              textContent,
              style: IrmaTheme.of(context).textTheme.body1,
              textAlign: TextAlign.center,
            ),
          )
        ]),
        Positioned(
          child: Align(
            alignment: FractionalOffset.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
              color: finalScreen ? IrmaTheme.of(context).backgroundBlue : null,
              child: finalScreen
                  ? IrmaButton(
                      label: 'enrollment.introduction.button_text',
                      onPressed: onPressButton,
                    )
                  : IconButton(
                      onPressed: onNextScreen,
                      icon: Icon(IrmaIcons.chevronDown, color: IrmaTheme.of(context).grayscale60),
                      iconSize: 16,
                      alignment: Alignment.center,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
