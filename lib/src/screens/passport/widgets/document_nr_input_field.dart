import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';

class DocumentNrInputField extends StatelessWidget {
  final TextEditingController controller;

  const DocumentNrInputField({
    required this.controller,
    super.key,
  });

  String? _validateDocumentNr(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return FlutterI18n.translate(
        context,
        'passport.manual.fields.document_nr_required',
      );
    }

    // ICAO-style: 6–9 alphanumeric characters (A–Z, 0–9)
    final pattern = RegExp(r'^[A-Z0-9]{6,9}$');
    if (!pattern.hasMatch(value)) {
      return FlutterI18n.translate(
        context,
        'passport.manual.fields.document_nr_invalid',
      );
    }

    return null; // valid
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    return TextFormField(
      key: const Key('document_nr_input_field'),
      controller: controller,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      autofillHints: const [AutofillHints.creditCardNumber],
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
      ],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: -10.0),
        label: TranslatedText(
          'passport.manual.fields.document_nr',
          style: baseTextStyle,
        ),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (documentNr) => _validateDocumentNr(documentNr, context),
    );
  }
}
