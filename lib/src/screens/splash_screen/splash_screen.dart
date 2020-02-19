import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class SplashScreen extends StatelessWidget {
  static const routeName = '/splash';

  final bool loading;

  const SplashScreen({
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: IrmaTheme.of(context).defaultSpacing,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 248,
                      height: 341,
                      child: SvgPicture.asset(
                        'assets/splash/splash.svg',
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 110.0,
                      width: 100.0,
                      // TODO: either irma logo or loading indicator, based on this.loading.
                      child: LoadingIndicator(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
