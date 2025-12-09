import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:mask_text_input_formatter/mask_text_input_formatter.dart";

import "../../../theme/theme.dart";

class DateInputField extends StatefulWidget {
  final TextEditingController controller;
  final Key? fieldKey;
  final String labelText;
  final String requiredText;
  final String dateInvalidText;

  /// Optional: date picker bounds & default.
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  /// Optional: how the picked date is rendered into the text field (defaults to yyyy-MM-dd).
  final String Function(BuildContext context, DateTime date)? formatDate;

  const DateInputField({
    required this.controller,
    required this.labelText,
    required this.requiredText,
    required this.dateInvalidText,
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
  final _dateFormat = DateFormat("yyyy-MM-dd");

  @override
  void initState() {
    super.initState();
    // Create ONCE so the formatter/caret state is stable during typing.
    _dateMask = MaskTextInputFormatter(
      mask: "####-##-##",
      filter: {"#": RegExp(r"\d")},
      type: .lazy,
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
      keyboardType: .number,
      textInputAction: .next,
      cursorColor: theme.themeData.colorScheme.secondary,
      style: baseTextStyle,
      inputFormatters: [_dateMask],
      decoration: InputDecoration(
        hintText: "YYYY-MM-DD",
        hintStyle: baseTextStyle?.copyWith(
          color: baseTextStyle.color?.withValues(alpha: 0.5),
        ),
        contentPadding: const .only(bottom: 8.0),
        labelText: widget.labelText,
        labelStyle: baseTextStyle,
        floatingLabelAlignment: .start,
        floatingLabelBehavior: .always,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final now = DateTime.now();
            final pickedDate = await showDatePicker(
              context: context,
              initialDatePickerMode: .day,
              initialEntryMode: .calendarOnly,
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
                selection: .collapsed(offset: text.length),
                composing: .empty,
              );
            }
          },
        ),
      ),
      autovalidateMode: .onUserInteraction,
      validator: (value) {
        final v = value?.trim() ?? "";
        if (v.isEmpty) {
          return widget.requiredText;
        }
        final parsed = _dateFormat.tryParseStrict(v);
        if (parsed == null) {
          return widget.dateInvalidText;
        }
        // Round-trip to ensure canonical yyyy-MM-dd (no partials like 2025-13-40)
        if (_dateFormat.format(parsed) != v) {
          return widget.dateInvalidText;
        }
        return null;
      },
    );
  }
}
