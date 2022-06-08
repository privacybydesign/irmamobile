import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/irma_icons.dart';
import '../theme/theme.dart';
import '../widgets/irma_bottom_bar.dart';
import 'irma_info_scaffold_body.dart';

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;
  final bool success;
  final String titleKey;
  final Map<String, String>? titleParams;
  final String explanationKey;
  final Map<String, String>? explanationParams;

  const ActionFeedback({
    required this.success,
    required this.titleKey,
    this.titleParams,
    required this.explanationKey,
    this.explanationParams,
    required this.onDismiss,
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
        body: IrmaInfoScaffoldBody(
          icon: success ? IrmaIcons.valid : IrmaIcons.invalid,
          iconColor: success ? IrmaTheme.of(context).interactionValid : IrmaTheme.of(context).interactionAlert,
          titleKey: titleKey,
          titleParams: titleParams,
          bodyKey: explanationKey,
          bodyParams: explanationParams,
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
          primaryButtonLabel: FlutterI18n.translate(context, 'action_feedback.ok'),
          onPrimaryPressed: () => dismiss(context),
        ),
      ),
    );
  }
}
