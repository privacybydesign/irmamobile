import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:mask_text_input_formatter/mask_text_input_formatter.dart";
import "package:material_ui/material_ui.dart";

import "../../../../data/feature_flags.dart";
import "../../../../providers/feature_flag_provider.dart";
import "../../../../theme/theme.dart";
import "../../../../widgets/yivi_text_field.dart";

class DateInputField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Key? fieldKey;
  final String labelText;
  final String requiredText;
  final String dateInvalidText;

  /// Optional: date picker bounds & default.
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;

  /// Optional: how the picked date is rendered into the text field (defaults to
  /// yyyy-MM-dd, or dd-MM-yyyy with form fields V2 on).
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
  ConsumerState<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends ConsumerState<DateInputField> {
  late final MaskTextInputFormatter _dateMask;
  late final MaskTextInputFormatter _dateMaskV2;
  final _dateFormat = DateFormat("yyyy-MM-dd");
  final _dateFormatV2 = DateFormat("dd-MM-yyyy");

  @override
  void initState() {
    super.initState();
    // Create ONCE so the formatter/caret state is stable during typing.
    _dateMask = MaskTextInputFormatter(
      mask: "####-##-##",
      filter: {"#": RegExp(r"\d")},
      type: .lazy,
    );
    _dateMaskV2 = MaskTextInputFormatter(
      mask: "##-##-####",
      filter: {"#": RegExp(r"\d")},
      type: .lazy,
    );
  }

  bool get _formFieldsV2 =>
      ref.read(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;

  DateFormat get _format => _formFieldsV2 ? _dateFormatV2 : _dateFormat;

  String _defaultFormat(BuildContext _, DateTime d) => _format.format(d);

  Future<void> _pickDate() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium;

    final formFieldsV2 =
        ref.watch(featureFlagProvider(FeatureFlag.formFieldsV2)).value ?? false;

    return YiviTextField(
      label: widget.labelText,
      hint: FlutterI18n.translate(context, "ui.date_placeholder"),
      suffixIcon: IconButton(
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: FlutterI18n.translate(context, "ui.choose_date"),
        icon: const Icon(Icons.calendar_today),
        onPressed: _pickDate,
      ),
      legacyDecoration: InputDecoration(
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
          onPressed: _pickDate,
        ),
      ),
      builder: (decoration, errorBuilder) => TextFormField(
        key: widget.fieldKey ?? const Key("date_input_field"),
        controller: widget.controller,
        readOnly: false,
        keyboardType: .number,
        textInputAction: .next,
        cursorColor: theme.themeData.colorScheme.secondary,
        style: baseTextStyle,
        inputFormatters: [formFieldsV2 ? _dateMaskV2 : _dateMask],
        decoration: decoration,
        errorBuilder: errorBuilder,
        autovalidateMode: .onUserInteraction,
        validator: (value) {
          final v = value?.trim() ?? "";
          if (v.isEmpty) {
            return widget.requiredText;
          }
          final parsed = _format.tryParseStrict(v);
          if (parsed == null) {
            return widget.dateInvalidText;
          }
          // Round-trip to ensure canonical yyyy-MM-dd (no partials like 2025-13-40)
          if (_format.format(parsed) != v) {
            return widget.dateInvalidText;
          }
          return null;
        },
      ),
    );
  }
}
