import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/translated_text.dart';

class NameChangedScreen extends StatelessWidget {
  final VoidCallback onContinuePressed;

  const NameChangedScreen({required this.onContinuePressed});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final oldLogoWidget = Image.asset('assets/non-free/logo_old.png', height: 120);

    final newLogoWidget = Image.asset('assets/non-free/logo.png', height: 150);

    final titleTextWidget = TranslatedText(
      'name_changed.title',
      style: theme.themeData.textTheme.displaySmall!.copyWith(color: theme.dark),
    );

    final headerTextWidget = TranslatedText(
      'name_changed.header',
      style: theme.themeData.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );

    final explanationTextWidget = TranslatedText(
      'name_changed.explanation',
      style: theme.themeData.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );

    Widget buildPortrait() => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        oldLogoWidget,
        SizedBox(height: theme.largeSpacing),
        titleTextWidget,
        SizedBox(height: theme.tinySpacing),
        headerTextWidget,
        Lottie.asset('assets/non-free/yivi_name_change.json', frameRate: FrameRate(60), repeat: false),
        explanationTextWidget,
      ],
    );

    Widget buildLandscape() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(mainAxisSize: MainAxisSize.min, children: [oldLogoWidget, newLogoWidget]),
        SizedBox(width: theme.largeSpacing),
        Flexible(
          flex: 2,
          child: Column(
            children: [
              titleTextWidget,
              SizedBox(height: theme.tinySpacing),
              TranslatedText(
                'name_changed.header',
                style: theme.themeData.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.tinySpacing),
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
            padding: EdgeInsets.all(theme.screenPadding),
            child: isLandscape ? buildLandscape() : buildPortrait(),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(primaryButtonLabel: 'action_feedback.ok', onPrimaryPressed: onContinuePressed),
    );
  }
}
