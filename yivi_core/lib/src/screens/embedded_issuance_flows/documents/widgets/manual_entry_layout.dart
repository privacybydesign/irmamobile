import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/translated_text.dart";
import "../document_instruction_screen.dart";

/// The body of the manual entry boards: a heading, the explanation, the
/// fields on one white card and a tip about where to find the details.
class ManualEntryLayout extends StatelessWidget {
  const ManualEntryLayout({
    required this.titleKey,
    required this.explanationKey,
    required this.tipKey,
    required this.fields,
    super.key,
  });

  final String titleKey;
  final String explanationKey;
  final String tipKey;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: TranslatedText(
            titleKey,
            isHeader: true,
            style: palette
                .display(24, weight: FontWeight.w700)
                .copyWith(height: 32 / 24, color: palette.heading),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: TranslatedText(
            explanationKey,
            style: palette.body(16).copyWith(height: 24 / 16),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: palette.surface,
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x17000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: fields,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DocumentTipBox(textKey: tipKey),
        ),
      ],
    );
  }
}

/// A manual entry field: the label above a 52 pt rounded input.
class DocumentField extends StatelessWidget {
  const DocumentField({required this.label, required this.field, super.key});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            label,
            style: palette
                .body(14, weight: FontWeight.w600)
                .copyWith(height: 20 / 14, color: palette.heading),
          ),
        ),
        field,
      ],
    );
  }
}

/// The input look of the manual entry boards: 52 pt high, radius 16, a
/// 1.5 pt outline that turns link blue on focus and red with an error.
InputDecoration documentFieldDecoration(
  BuildContext context, {
  required String hint,
  Widget? suffixIcon,
}) {
  final palette = YiviPalette.of(context);
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide(color: color, width: 1.5),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: palette.surface,
    hintText: hint,
    hintStyle: palette.body(16).copyWith(color: palette.secondaryText),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minHeight: 48, minWidth: 48),
    enabledBorder: border(palette.outline),
    focusedBorder: border(palette.link),
    errorBorder: border(palette.danger),
    focusedErrorBorder: border(palette.danger),
    errorStyle: palette
        .body(14, weight: FontWeight.w600)
        .copyWith(color: palette.danger),
  );
}

/// The text style inside a manual entry field.
TextStyle documentFieldText(BuildContext context, {double spacing = 0}) {
  final palette = YiviPalette.of(context);
  return palette.body(16).copyWith(color: palette.text, letterSpacing: spacing);
}
