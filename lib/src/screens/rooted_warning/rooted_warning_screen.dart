import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../theme/theme.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/translated_text.dart';

class RootedWarningScreen extends StatelessWidget {
  final VoidCallback? onAcceptRiskButtonPressed;

  const RootedWarningScreen({
    this.onAcceptRiskButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(theme.largeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.gpp_bad_outlined,
              color: Colors.red,
              size: 125,
            ),
            SizedBox(
              height: theme.mediumSpacing,
            ),
            TranslatedText(
              'rooted_warning.title',
              style: theme.textTheme.headline1,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: theme.mediumSpacing,
            ),
            TranslatedText(
              'rooted_warning.explanation',
              style: theme.textTheme.bodyText2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        key: const Key('warning_screen_accept_button'),
        primaryButtonLabel: FlutterI18n.translate(context, 'rooted_warning.accept_risk'),
        onPrimaryPressed: () => onAcceptRiskButtonPressed?.call(),
      ),
    );
  }
}
