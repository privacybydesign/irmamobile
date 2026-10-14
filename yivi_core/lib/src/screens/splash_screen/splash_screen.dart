import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../theme/yivi_palette.dart";
import "../../util/test_detection.dart";
import "../../widgets/loading_indicator.dart";

/// The Yivi logo on the plain background, growing in, with the slogan at the
/// bottom. The logo has no black lettering, so it reads in dark mode too.
class SplashScreen extends StatelessWidget {
  static const routeName = "/splash";

  final bool isLoading;

  const SplashScreen({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final still =
        MediaQuery.disableAnimationsOf(context) ||
        TestContext.isRunningIntegrationTest(context);

    final logo = SvgPicture.asset(
      yiviAsset("non-free/logo_no_margin.svg"),
      width: 168,
      semanticsLabel: FlutterI18n.translate(context, "accessibility.irma_logo"),
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  still
                      ? logo
                      : TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 900),
                          curve: const Cubic(0.2, 0.8, 0.2, 1),
                          child: logo,
                          builder: (context, t, child) => Opacity(
                            opacity: (t * 1.6).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.86 + 0.14 * t,
                              child: child,
                            ),
                          ),
                        ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: LoadingIndicator(),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: Text(
                FlutterI18n.translate(context, "more_tab.slogan"),
                textAlign: TextAlign.center,
                style: palette
                    .body(14)
                    .copyWith(height: 20 / 14, color: palette.secondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
