import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/glass/pill_buttons.dart";
import "../../../../widgets/irma_dialog.dart";
import "../../../../widgets/pill_text_field.dart";

class ProvideSchemeUrlDialog extends StatefulWidget {
  const ProvideSchemeUrlDialog({super.key});

  @override
  State<ProvideSchemeUrlDialog> createState() => _ProvideSchemeUrlDialogState();
}

class _ProvideSchemeUrlDialogState extends State<ProvideSchemeUrlDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final navigator = Navigator.of(context);

    final translatedTitle = FlutterI18n.translate(
      context,
      "debug.scheme_management.install_scheme_dialog.title",
    );
    final translatedContent = FlutterI18n.translate(
      context,
      "debug.scheme_management.install_scheme_dialog.content",
    );

    return IrmaDialog(
      title: translatedTitle,
      content: translatedContent,
      child: Wrap(
        runSpacing: theme.defaultSpacing,
        alignment: WrapAlignment.center,
        children: [
          PillTextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            hint: "https://",
            onSubmitted: (url) => navigator.pop(url),
          ),
          FancyPillButton(
            label: FlutterI18n.translate(context, "ui.add"),
            size: PillSize.regular,
            onPressed: () => navigator.pop(controller.text),
          ),
        ],
      ),
    );
  }
}
