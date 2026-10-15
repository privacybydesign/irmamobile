import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";
import "../../../../widgets/pill_text_field.dart";

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
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    return TextFormField(
      key: const Key("document_nr_input_field"),
      controller: controller,
      keyboardType: .text,
      textCapitalization: .characters,
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
      ],
      decoration: pillInputDecoration(
        context,
        label: labelText,
        hint: labelText,
      ),
      autovalidateMode: .onUserInteraction,
      validator: (documentNr) => _validateDocumentNr(documentNr, context),
    );
  }
}
