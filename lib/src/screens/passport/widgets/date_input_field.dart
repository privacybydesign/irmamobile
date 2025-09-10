import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';

class DateInputField extends StatelessWidget {
  final TextEditingController controller;

  /// Optional: override the TextFormField key.
  final Key? fieldKey;

  /// I18n key for the field label (e.g. 'passport.manual.fields.date').
  final String labelI18nKey;

  /// I18n key for the "required" validation message.
  final String requiredI18nKey;

  /// Optional: date picker bounds & default.
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  /// Optional: how the picked date is rendered into the text field.
  /// Default is ISO yyyy-MM-dd.
  final String Function(BuildContext context, DateTime date)? formatDate;

  const DateInputField({
    required this.controller,
    required this.labelI18nKey,
    required this.requiredI18nKey,
    this.fieldKey,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.formatDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    // Default formatting: yyyy-MM-dd
    String defaultFormat(BuildContext _, DateTime d) => '${d.toLocal()}'.split(' ').first;

    return TextFormField(
      key: fieldKey ?? const Key('date_input_field'),
      controller: controller,
      readOnly: true, // force use of the date picker
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(top: -10.0),
        label: TranslatedText(
          labelI18nKey,
          style: baseTextStyle,
        ),
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return FlutterI18n.translate(context, requiredI18nKey);
        }
        return null;
      },
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode()); // hide keyboard
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime(now.year - 25),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (pickedDate != null) {
          final fmt = formatDate ?? defaultFormat;
          if (!context.mounted) return;
          controller.text = fmt(context, pickedDate);
        }
      },
    );
  }
}
