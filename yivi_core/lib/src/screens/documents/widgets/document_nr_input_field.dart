import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../../theme/theme.dart";

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
      autofillHints: const [AutofillHints.creditCardNumber],
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
      ],
      decoration: InputDecoration(
        hint: Text(
          labelText,
          style: baseTextStyle?.copyWith(
            color: baseTextStyle.color?.withValues(alpha: 0.5),
          ),
        ),
        contentPadding: const EdgeInsets.only(top: -10.0),
        label: Text(labelText, style: baseTextStyle),
        floatingLabelAlignment: .start,
        floatingLabelBehavior: .always,
      ),
      autovalidateMode: .onUserInteraction,
      validator: (documentNr) => _validateDocumentNr(documentNr, context),
    );
  }
}
