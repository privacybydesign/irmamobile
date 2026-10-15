import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "manual_entry_layout.dart";

class DrivingLicenceMrzInputField extends StatelessWidget {
  final TextEditingController controller;

  const DrivingLicenceMrzInputField({required this.controller, super.key});

  String? _validateDocumentNr(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return FlutterI18n.translate(
        context,
        "driving_licence.manual.fields.mrz_required",
      );
    }

    // Exactly 30 alpha numeric characters (only capital letters allowed)
    final pattern = RegExp(r"^[A-Z0-9]{30}$");
    if (!pattern.hasMatch(value)) {
      return FlutterI18n.translate(
        context,
        "driving_licence.manual.fields.mrz_invalid",
      );
    }

    return null; // valid
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final label = FlutterI18n.translate(
      context,
      "driving_licence.manual.fields.mrz",
    );

    return DocumentField(
      label: label,
      field: TextFormField(
        key: const Key("driving_licence_mrz_input_field"),
        controller: controller,
        keyboardType: .text,
        textCapitalization: .characters,
        autofillHints: const [AutofillHints.creditCardNumber],
        cursorColor: palette.link,
        style: documentFieldText(context, spacing: 16 * 0.04),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
        ],
        decoration: documentFieldDecoration(context, hint: label),
        autovalidateMode: .onUserInteraction,
        validator: (documentNr) => _validateDocumentNr(documentNr, context),
      ),
    );
  }
}
