import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../theme/theme.dart';

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
    // Using an independant mask here, since on Samsung devices, the input formatter for dates will not add "-" or "/" separators
    final dateMask =
        MaskTextInputFormatter(mask: '####-##-##', filter: {'#': RegExp(r'[0-9]')}, type: MaskAutoCompletionType.lazy);

    // Default formatting: yyyy-MM-dd
    String defaultFormat(BuildContext _, DateTime d) => '${d.toLocal()}'.split(' ').first;

    return TextFormField(
      key: fieldKey ?? const Key('date_input_field'),
      controller: controller,
      readOnly: false,
      inputFormatters: [dateMask],
      keyboardType: TextInputType.number,
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      decoration: InputDecoration(
        hintText: 'YYYY-MM-DD',
        hintStyle: baseTextStyle?.apply(color: baseTextStyle.color?.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.only(bottom: 8.0),
        labelText: FlutterI18n.translate(context, labelI18nKey),
        labelStyle: baseTextStyle,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
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
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return FlutterI18n.translate(context, requiredI18nKey);
        }
        return null;
      },
    );
  }
}
