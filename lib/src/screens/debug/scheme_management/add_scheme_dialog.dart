import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_dialog.dart';
import '../../../widgets/yivi_themed_button.dart';

class AddSchemeDialog extends StatelessWidget {
  final TextEditingController controller;

  const AddSchemeDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final navigator = Navigator.of(context);

    final translatedTitle = FlutterI18n.translate(context, 'debug.scheme_management.add_scheme_dialog.title');
    final translatedContent = FlutterI18n.translate(context, 'debug.scheme_management.add_scheme_dialog.content');

    return IrmaDialog(
      title: translatedTitle,
      content: translatedContent,
      child: Wrap(
        runSpacing: theme.defaultSpacing,
        alignment: WrapAlignment.center,
        children: [
          TextField(
            controller: controller,
            autocorrect: false,
            autofocus: true,
            onSubmitted: (url) => navigator.pop(url),
          ),
          YiviThemedButton(
            label: 'ui.add',
            onPressed: () => navigator.pop(controller.text),
          ),
        ],
      ),
    );
  }
}
