import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../widgets/irma_bottom_bar.dart';
import 'irma_info_scaffold_body.dart';

class ActionFeedback extends StatelessWidget {
  final Function() onDismiss;
  final bool success;
  final String titleTranslationKey;
  final Map<String, String>? titleTranslationParams;
  final String explanationTranslationKey;
  final Map<String, String>? explanationTranslationParams;

  const ActionFeedback({
    required this.success,
    required this.titleTranslationKey,
    this.titleTranslationParams,
    required this.explanationTranslationKey,
    this.explanationTranslationParams,
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
          imagePath: success
              ? 'assets/disclosure/disclosure_happy_illustration.svg'
              : 'assets/error/general_error_illustration.svg',
          titleTranslationKey: titleTranslationKey,
          titleTranslationParams: titleTranslationParams,
          bodyTranslationKey: explanationTranslationKey,
          bodyTranslationParams: explanationTranslationParams,
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: IconButton(
                  enableFeedback: true,
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
