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

  @override
  Widget build(BuildContext context) => DocumentCodeField(
    fieldKey: const Key("document_nr_input_field"),
    controller: controller,
    label: labelText,
    hint: FlutterI18n.translate(
      context,
      "document_flow.manual.document_nr_hint",
    ),
    // ICAO-style: 6–9 alphanumeric characters (A–Z, 0–9)
    pattern: RegExp(r"^[A-Z0-9]{6,9}$"),
    requiredText: requiredText,
    invalidText: invalidText,
  );
}

/// A field for a code from a document (its number, a licence's MRZ):
/// capitals and digits only, a little spaced, checked against [pattern]
/// once the user has typed.
class DocumentCodeField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final RegExp pattern;
  final String requiredText;
  final String invalidText;
  final Iterable<String>? autofillHints;

  const DocumentCodeField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.pattern,
    required this.requiredText,
    required this.invalidText,
    this.autofillHints,
  });

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return requiredText;
    if (!pattern.hasMatch(value)) return invalidText;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DocumentField(
      label: label,
      field: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: .text,
        textCapitalization: .characters,
        autofillHints: autofillHints,
        cursorColor: YiviPalette.of(context).link,
        // A little spacing helps reading a code.
        style: documentFieldText(context, spacing: 16 * 0.04),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
        ],
        decoration: documentFieldDecoration(context, hint: hint),
        autovalidateMode: .onUserInteraction,
        validator: _validate,
      ),
    );
  }
}
