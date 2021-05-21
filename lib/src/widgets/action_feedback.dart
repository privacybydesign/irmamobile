import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';
import 'package:irmamobile/src/widgets/irma_outlined_button.dart';

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;

  final bool success;
  final TranslatedText title;
  final TranslatedText explanation;

  const ActionFeedback({
    @required this.success,
    @required this.title,
    @required this.explanation,
    @required this.onDismiss,
  });

  void dismiss(BuildContext context) {
    Navigator.of(context).pop();
    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        dismiss(context);
        return false;
      },
      child: Scaffold(
        // This screen intentionally doesn't container an AppBar, as this screen can be closed
        // to get the app back. Otherwise, strange routes such as the settings or side menu
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
              child: title,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).mediumSpacing),
              child: explanation,
            ),
            const SizedBox(height: 38),
            IrmaOutlinedButton(
              key: const Key('feedback_dismiss'),
              label: FlutterI18n.translate(context, "action_feedback.ok"),
              onPressed: () => dismiss(context),
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
