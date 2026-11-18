import "package:material_ui/material_ui.dart";

import "../../../../models/eudi_configuration.dart";
import "../../../../theme/yivi_space.dart";
import "../../../../util/i18n.dart";
import "../../../../widgets/buttons/pill_buttons.dart";
import "../../../../widgets/feedback/glass_dialog.dart";

class ProvideCertDialog extends StatefulWidget {
  const ProvideCertDialog({super.key});

  @override
  State<ProvideCertDialog> createState() => _ProvideCertDialogState();
}

class _ProvideCertDialogState extends State<ProvideCertDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var certType = "issuer";

    final navigator = Navigator.of(context);

    final translatedTitle = context.tr(
      "debug.cert_management.install_cert_dialog.title",
    );
    final translatedContent = context.tr(
      "debug.cert_management.install_cert_dialog.content",
    );

    return GlassDialog(
      title: translatedTitle,
      message: translatedContent,
      body: Column(
        spacing: YiviSpace.x16,
        children: [
          DropdownMenu(
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: "issuer", label: "Issuer"),
              DropdownMenuEntry(value: "verifier", label: "Verifier"),
            ],
            initialSelection: certType,
            onSelected: (value) => certType = value!,
          ),
          SizedBox(
            height: 200,
            child: TextField(
              expands: true,
              maxLines: null,
              controller: controller,
              autocorrect: false,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              onSubmitted: (pemContent) => navigator.pop(
                NewCertificate(type: certType, pemContent: pemContent),
              ),
            ),
          ),
        ],
      ),
      actions: [
        FancyPillButton(
          label: context.tr("ui.add"),
          size: PillSize.regular,
          onPressed: () => navigator.pop(
            NewCertificate(type: certType, pemContent: controller.text),
          ),
        ),
      ],
    );
  }
}
