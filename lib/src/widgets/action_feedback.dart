import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_bottom_bar.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;

  final bool success;
  final TranslatedText title;
  final TranslatedText explanation;

  const ActionFeedback({
    required this.success,
    required this.title,
    required this.explanation,
    required this.onDismiss,
  });

  void dismiss(BuildContext context) {
    Navigator.of(context).pop();
    onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return WillPopScope(
      onWillPop: () async {
        dismiss(context);
        return false;
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(theme.largeSpacing),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    success ? IrmaIcons.valid : IrmaIcons.invalid,
                    size: 120,
                    color: success ? IrmaTheme.of(context).interactionValid : IrmaTheme.of(context).interactionAlert,
                  ),
                  SizedBox(height: theme.mediumSpacing),
                  title,
                  SizedBox(height: theme.mediumSpacing),
                  explanation,
                ],
              ),
            ),
          ),
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: IconButton(
                  onPressed: () => dismiss(context),
                  icon: Icon(
                    Icons.close_outlined,
                    semanticLabel: FlutterI18n.translate(context, 'accessibility.close'),
                    size: 16.0,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: IrmaBottomBar(
          primaryButtonLabel: FlutterI18n.translate(context, "action_feedback.ok"),
          onPrimaryPressed: () => dismiss(context),
        ),
      ),
    );
  }
}
