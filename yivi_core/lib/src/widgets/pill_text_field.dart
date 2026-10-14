import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// A text field in the glass style: a label above it, a rounded field on the
/// surface colour, an outline that turns link blue on focus and red with an
/// error, and the error below it as an alert.
class PillTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final int? minLines;
  final int maxLines;

  /// Shown in front of the text, e.g. a country code.
  final Widget? prefix;

  /// The key of the inner [TextField], for tests.
  final Key? fieldKey;

  const PillTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.prefix,
    this.fieldKey,
  });

  static const _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final hasError = (errorText ?? "").isNotEmpty;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: 1.5),
    );

    final field = TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      autofocus: autofocus,
      obscureText: obscureText,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: palette.link,
      style: palette.body(16),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: palette.surface,
        hintText: hint,
        hintStyle: palette.body(16).copyWith(color: palette.secondaryText),
        prefixIcon: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 18, right: 8),
                child: prefix,
              ),
        prefixIconConstraints: const BoxConstraints(minHeight: 56),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefix == null ? 20 : 0,
          vertical: 17,
        ),
        enabledBorder: border(hasError ? palette.danger : palette.outline),
        disabledBorder: border(palette.divider),
        focusedBorder: border(hasError ? palette.danger : palette.link),
        // The error is shown below as an alert, not by the decoration.
        errorText: null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              label!,
              style: palette
                  .body(14, weight: FontWeight.w600)
                  .copyWith(height: 20 / 14, color: palette.heading),
            ),
          ),
        Semantics(label: label, textField: true, child: field),
        if (hasError) FieldError(errorText!),
      ],
    );
  }
}

/// A red warning line under a field, announced as soon as it appears.
class FieldError extends StatelessWidget {
  final String text;
  final TextAlign align;

  const FieldError(this.text, {super.key, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Semantics(
        liveRegion: true,
        child: Row(
          mainAxisAlignment: align == TextAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.warning_rounded,
                size: 16,
                color: palette.danger,
              ),
            ),
            Flexible(
              child: Text(
                text,
                textAlign: align,
                style: palette
                    .body(14, weight: FontWeight.w600)
                    .copyWith(height: 20 / 14, color: palette.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
