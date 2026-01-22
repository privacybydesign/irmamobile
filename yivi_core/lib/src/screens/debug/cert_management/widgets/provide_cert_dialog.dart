import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../../models/eudi_configuration.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/irma_dialog.dart";
import "../../../../widgets/yivi_themed_button.dart";

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

    final theme = IrmaTheme.of(context);
    final navigator = Navigator.of(context);

    final translatedTitle = FlutterI18n.translate(
      context,
      "debug.cert_management.install_cert_dialog.title",
    );
    final translatedContent = FlutterI18n.translate(
      context,
      "debug.cert_management.install_cert_dialog.content",
    );

    return IrmaDialog(
      title: translatedTitle,
      content: translatedContent,
      child: Wrap(
        runSpacing: theme.defaultSpacing,
        alignment: WrapAlignment.center,
        children: [
          DropdownMenu(
            dropdownMenuEntries: [
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
          YiviThemedButton(
            label: "ui.add",
            onPressed: () => navigator.pop(
              NewCertificate(type: certType, pemContent: controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
