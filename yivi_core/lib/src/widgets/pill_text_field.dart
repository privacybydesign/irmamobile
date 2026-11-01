import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";

/// The label above a field, here and on the document and contact screens.
TextStyle fieldLabelStyle(BuildContext context) {
  final palette = YiviPalette.of(context);
  return palette
      .body(14, weight: FontWeight.w600)
      .copyWith(height: 20 / 14, color: palette.heading);
}

/// A text field: a label above it, a rounded field on the surface colour,
/// and an outline that turns link blue on focus.
class PillTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int? minLines;
  final int maxLines;

  /// The key of the inner [TextField], for tests.
  final Key? fieldKey;

  const PillTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onSubmitted,
    this.keyboardType,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
    this.fieldKey,
  });

  static const _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: color, width: 1.5),
    );

    final field = TextField(
      key: fieldKey,
      controller: controller,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      autofocus: autofocus,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 17,
        ),
        enabledBorder: border(palette.outline),
        focusedBorder: border(palette.link),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(label!, style: fieldLabelStyle(context)),
          ),
        Semantics(label: label, textField: true, child: field),
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

/// The look of [PillTextField] for a [TextFormField] that keeps its own
/// validator: a rounded field on the surface colour with the label above it
/// in the outline, link blue on focus, red with an error.
InputDecoration pillInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  Widget? suffixIcon,
}) {
  final palette = YiviPalette.of(context);
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: PillTextField._radius,
    borderSide: BorderSide(color: color, width: 1.5),
  );
  return InputDecoration(
    filled: true,
    fillColor: palette.surface,
    labelText: label,
    labelStyle: palette
        .body(14, weight: FontWeight.w600)
        .copyWith(color: palette.heading),
    floatingLabelStyle: palette
        .body(14, weight: FontWeight.w600)
        .copyWith(color: palette.heading),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    hintText: hint,
    hintStyle: palette.body(16).copyWith(color: palette.secondaryText),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    suffixIcon: suffixIcon,
    enabledBorder: border(palette.outline),
    focusedBorder: border(palette.link),
    errorBorder: border(palette.danger),
    focusedErrorBorder: border(palette.danger),
    errorStyle: palette
        .body(14, weight: FontWeight.w600)
        .copyWith(color: palette.danger),
  );
}
