import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:lottie/lottie.dart';

import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/irma_markdown.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class NameChangeScreen extends StatelessWidget {
  final VoidCallback onContinuePressed;

  const NameChangeScreen({
    required this.onContinuePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // Overwrite  markdown style with text align center
    final markdownStyleSheet = MarkdownStyleSheet.fromTheme(theme.themeData).merge(
      MarkdownStyleSheet(
        textAlign: WrapAlignment.center,
        strong: theme.textTheme.bodyText1,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
      ),
    );

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: theme.largeSpacing,
          left: theme.defaultSpacing,
          right: theme.defaultSpacing,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Center(
                child: Column(
                  children: [
                    IrmaMarkdown(
                      FlutterI18n.translate(
                        context,
                        'name_change.intro_markdown',
                      ),
                      styleSheet: markdownStyleSheet,
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: theme.largeSpacing,
                        ),
                        child: Lottie.asset(
                          'assets/non-free/yivi_name_change.json',
                          frameRate: FrameRate(60),
                          repeat: false,
                        )),
                    const TranslatedText(
                      'name_change.explanation',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: theme.defaultSpacing,
                    ),
                    const TranslatedText(
                      'name_change.release',
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: 'name_change.ok',
        onPrimaryPressed: onContinuePressed,
      ),
    );
  }
}
