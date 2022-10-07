import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/theme.dart';
import '../../widgets/loading_indicator.dart';

class SplashScreen extends StatelessWidget {
  static const routeName = '/splash';

  final bool isLoading;

  const SplashScreen({
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > 450;

    final logoWidth = screenSize.width * (isLandscape ? 0.25 : 0.5);
    final logoHeight = logoWidth * (isLandscape ? 0.80 : 1.20);

    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'assets/non-free/logo_payoff.svg',
              height: logoHeight,
              width: logoWidth,
              semanticsLabel: FlutterI18n.translate(
                context,
                'accessibility.irma_logo',
              ),
            ),
            if (isLoading)
              Container(
                margin: EdgeInsets.only(
                  top: logoHeight + IrmaTheme.of(context).defaultSpacing,
                ),
                child: LoadingIndicator(),
              )
          ],
        ),
      ),
    );
  }
}
