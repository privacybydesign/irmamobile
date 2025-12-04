import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";
import "package:mask_text_input_formatter/mask_text_input_formatter.dart";

import "../../../theme/theme.dart";

class DateInputField extends StatefulWidget {
  final TextEditingController controller;
  final Key? fieldKey;
  final String labelI18nKey;
  final String requiredI18nKey;

  /// Optional: date picker bounds & default.
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  /// Optional: how the picked date is rendered into the text field (defaults to yyyy-MM-dd).
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
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final MaskTextInputFormatter _dateMask;
  final _invalidI18nKey = "passport.manual.fields.date_invalid";
  final _dateFormat = DateFormat("yyyy-MM-dd");

  @override
  void initState() {
    super.initState();
    // Create ONCE so the formatter/caret state is stable during typing.
    _dateMask = MaskTextInputFormatter(
      mask: "####-##-##",
      filter: {"#": RegExp(r"\d")},
      type: MaskAutoCompletionType.lazy,
    );
  }

  String _defaultFormat(BuildContext _, DateTime d) => _dateFormat.format(d);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    return TextFormField(
      key: widget.fieldKey ?? const Key("date_input_field"),
      controller: widget.controller,
      readOnly: false,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      inputFormatters: <TextInputFormatter>[_dateMask],
      decoration: InputDecoration(
        hintText: "YYYY-MM-DD",
        hintStyle: baseTextStyle?.copyWith(
          color: baseTextStyle.color?.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.only(bottom: 8.0),
        labelText: FlutterI18n.translate(context, widget.labelI18nKey),
        labelStyle: baseTextStyle,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDatePickerMode: DatePickerMode.day,
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              initialDate: widget.initialDate ?? DateTime(now.year - 25),
              firstDate: widget.firstDate ?? DateTime(1900),
              lastDate: widget.lastDate ?? DateTime(2100),
            );
            if (pickedDate != null && mounted) {
              final fmt = widget.formatDate ?? _defaultFormat;
              if (!context.mounted) {
                return;
              }
              final text = fmt(context, pickedDate);
              // Set both text and caret to end to avoid selection glitches.
              widget.controller.value = widget.controller.value.copyWith(
                text: text,
                selection: TextSelection.collapsed(offset: text.length),
                composing: TextRange.empty,
              );
            }
          },
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        final v = value?.trim() ?? "";
        if (v.isEmpty) {
          return FlutterI18n.translate(context, widget.requiredI18nKey);
        }
        final parsed = _dateFormat.tryParseStrict(v);
        if (parsed == null) {
          return FlutterI18n.translate(context, _invalidI18nKey);
        }
        // Round-trip to ensure canonical yyyy-MM-dd (no partials like 2025-13-40)
        if (_dateFormat.format(parsed) != v) {
          return FlutterI18n.translate(context, _invalidI18nKey);
        }
        return null;
      },
    );
  }
}
