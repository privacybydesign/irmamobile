import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';

class DisclosureFeedbackScreen extends StatelessWidget {
  final bool success;
  final String otherParty;
  final Function(BuildContext) popToWallet;

  const DisclosureFeedbackScreen({this.success, this.otherParty, this.popToWallet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            success ? IrmaIcons.valid : IrmaIcons.invalid,
            size: 120,
            color: success ? IrmaTheme.of(context).interactionValid : IrmaTheme.of(context).interactionAlert,
          ),
          const SizedBox(height: 43),
          TranslatedText(
            "disclosure.feedback.header.$success",
            translationParams: {"otherParty": otherParty},
            style: Theme.of(context).textTheme.display3,
          ),
          const SizedBox(height: 10),
          TranslatedText(
            "disclosure.feedback.text.$success",
            translationParams: {"otherParty": otherParty},
            textAlign: TextAlign.center,
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
    );
  }
}
