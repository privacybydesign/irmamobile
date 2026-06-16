import "package:flutter/material.dart";
import "package:lottie/lottie.dart";

import "../../../package_name.dart";
import "../../theme/theme.dart";
import "../../widgets/irma_bottom_bar.dart";
import "../../widgets/translated_text.dart";

class NameChangedScreen extends StatelessWidget {
  final VoidCallback onContinuePressed;

  const NameChangedScreen({super.key, required this.onContinuePressed});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final oldLogoWidget = Image.asset(
      yiviAsset("non-free/logo_old.png"),
      height: 120,
    );

    final newLogoWidget = Image.asset(
      yiviAsset("non-free/logo.png"),
      height: 150,
    );

    final titleTextWidget = TranslatedText(
      "name_changed.title",
      style: context.text.displaySmall!.copyWith(
        color: context.colors.onSurface,
      ),
    );

    final headerTextWidget = TranslatedText(
      "name_changed.header",
      style: context.text.bodyMedium,
      textAlign: TextAlign.center,
    );

    final explanationTextWidget = TranslatedText(
      "name_changed.explanation",
      style: context.text.bodyMedium,
      textAlign: TextAlign.center,
    );

    Widget buildPortrait() => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        oldLogoWidget,
        SizedBox(height: context.yivi.largeSpacing),
        titleTextWidget,
        SizedBox(height: context.yivi.tinySpacing),
        headerTextWidget,
        Lottie.asset(
          yiviAsset("non-free/yivi_name_change.json"),
          frameRate: FrameRate(60),
          repeat: false,
        ),
        explanationTextWidget,
      ],
    );

    Widget buildLandscape() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [oldLogoWidget, newLogoWidget],
        ),
        SizedBox(width: context.yivi.largeSpacing),
        Flexible(
          flex: 2,
          child: Column(
            children: [
              titleTextWidget,
              SizedBox(height: context.yivi.tinySpacing),
              TranslatedText(
                "name_changed.header",
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.yivi.tinySpacing),
              explanationTextWidget,
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.yivi.screenPadding),
            child: isLandscape ? buildLandscape() : buildPortrait(),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "action_feedback.ok",
        onPrimaryPressed: onContinuePressed,
      ),
    );
  }
}
