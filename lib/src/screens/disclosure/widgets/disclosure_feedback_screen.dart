import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';

enum DisclosureFeedbackType {
  success,
  canceled,
  notSatisfiable,
}

class DisclosureFeedbackScreen extends StatelessWidget {
  static const _translationKeys = {
    DisclosureFeedbackType.success: "success",
    DisclosureFeedbackType.canceled: "canceled",
    DisclosureFeedbackType.notSatisfiable: "notSatisfiable",
  };

  final DisclosureFeedbackType feedbackType;
  final String otherParty;
  final Function(BuildContext) popToWallet;

  final String _translationKey;

  DisclosureFeedbackScreen({this.feedbackType, this.otherParty, this.popToWallet})
      : _translationKey = _translationKeys[feedbackType];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        popToWallet(context);
        return false;
      },
      child: Scaffold(
        // This screen intentionally doesn't container an AppBar, as this screen can be closed
        // to get the app bac back. Otherwise, strange routes such as the settings or side menu
        // could be pushed on top of this screen, where it doesn't make sense
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Icon(
              feedbackType == DisclosureFeedbackType.success ? IrmaIcons.valid : IrmaIcons.invalid,
              size: 120,
              color: feedbackType == DisclosureFeedbackType.success
                  ? IrmaTheme.of(context).interactionValid
                  : IrmaTheme.of(context).interactionAlert,
            ),
            const SizedBox(height: 43),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
              child: TranslatedText(
                "disclosure.feedback.header.$_translationKey",
                translationParams: {"otherParty": otherParty},
                style: Theme.of(context).textTheme.display3,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
              child: TranslatedText(
                "disclosure.feedback.text.$_translationKey",
                translationParams: {"otherParty": otherParty},
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 38),
            IrmaOutlinedButton(
              label: FlutterI18n.translate(context, "disclosure.feedback.ok"),
              onPressed: () => popToWallet(context),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
