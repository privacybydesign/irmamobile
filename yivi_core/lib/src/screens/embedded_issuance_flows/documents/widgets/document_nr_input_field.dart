import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "manual_entry_layout.dart";

class DocumentNrInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String requiredText;
  final String invalidText;

  const DocumentNrInputField({
    required this.controller,
    super.key,
    required this.labelText,
    required this.requiredText,
    required this.invalidText,
  });

  String? _validateDocumentNr(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return requiredText;
    }

    // ICAO-style: 6–9 alphanumeric characters (A–Z, 0–9)
    final pattern = RegExp(r"^[A-Z0-9]{6,9}$");
    if (!pattern.hasMatch(value)) {
      return invalidText;
    }

    return null; // valid
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return DocumentField(
      label: labelText,
      field: TextFormField(
        key: const Key("document_nr_input_field"),
        controller: controller,
        keyboardType: .text,
        textCapitalization: .characters,
        cursorColor: palette.link,
        // A little spacing helps reading a code.
        style: documentFieldText(context, spacing: 16 * 0.04),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
        ],
        decoration: documentFieldDecoration(
          context,
          hint: FlutterI18n.translate(
            context,
            "document_flow.manual.document_nr_hint",
          ),
        ),
        autovalidateMode: .onUserInteraction,
        validator: (documentNr) => _validateDocumentNr(documentNr, context),
      ),
    );
  }
}
