import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class SplashScreen extends StatelessWidget {
  static const routeName = '/splash';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / 3;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: IrmaTheme.of(context).defaultSpacing,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: width,
                  width: width,
                  child: LoadingIndicator(
                    size: width,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
