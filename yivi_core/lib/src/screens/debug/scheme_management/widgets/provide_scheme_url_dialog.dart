import "package:material_ui/material_ui.dart";

import "../../../../util/i18n.dart";
import "../../../../widgets/buttons/pill_buttons.dart";
import "../../../../widgets/feedback/glass_dialog.dart";
import "../../../../widgets/input/pill_text_field.dart";

class ProvideSchemeUrlDialog extends StatefulWidget {
  const ProvideSchemeUrlDialog({super.key});

  @override
  State<ProvideSchemeUrlDialog> createState() => _ProvideSchemeUrlDialogState();
}

class _ProvideSchemeUrlDialogState extends State<ProvideSchemeUrlDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    final translatedTitle = context.tr(
      "debug.scheme_management.install_scheme_dialog.title",
    );
    final translatedContent = context.tr(
      "debug.scheme_management.install_scheme_dialog.content",
    );

    return GlassDialog(
      title: translatedTitle,
      message: translatedContent,
      body: PillTextField(
        controller: controller,
        keyboardType: TextInputType.url,
        hint: "https://",
        onSubmitted: (url) => navigator.pop(url),
      ),
      actions: [
        FancyPillButton(
          label: context.tr("ui.add"),
          size: PillSize.regular,
          onPressed: () => navigator.pop(controller.text),
        ),
      ],
    );
  }
}
