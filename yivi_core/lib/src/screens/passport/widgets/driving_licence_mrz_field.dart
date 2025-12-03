import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../theme/theme.dart";
import "../../../widgets/translated_text.dart";

class DrivingLicenceMrzInputField extends StatelessWidget {
  final TextEditingController controller;

  const DrivingLicenceMrzInputField({required this.controller, super.key});

  String? _validateDocumentNr(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return FlutterI18n.translate(
        context,
        "driving_licence.manual.fields.mrdocument_mrz_required",
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
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    return TextFormField(
      key: const Key("driving_licence_mrz_input_field"),
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
        hint: TranslatedText(
          "driving_licence.manual.fields.mrz",
          style: baseTextStyle?.copyWith(
            color: baseTextStyle.color?.withValues(alpha: 0.5),
          ),
        ),
        contentPadding: const EdgeInsets.only(top: -10.0),
        label: TranslatedText(
          "driving_licence.manual.fields.mrz",
          style: baseTextStyle,
        ),
        floatingLabelAlignment: .start,
        floatingLabelBehavior: .always,
      ),
      autovalidateMode: .onUserInteraction,
      validator: (documentNr) => _validateDocumentNr(documentNr, context),
    );
  }
}
