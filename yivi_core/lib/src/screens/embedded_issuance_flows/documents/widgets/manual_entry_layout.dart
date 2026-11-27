import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "../../../../theme/yivi_space.dart";
import "../../../../util/adaptive_layout.dart";
import "../../../../widgets/input/pill_text_field.dart";
import "../../../../widgets/sheet/sheet_layout.dart";
import "../../../../widgets/surfaces/surface_card.dart";
import "../../../../widgets/text/translated_text.dart";
import "../document_instruction_screen.dart";
import "../document_step_in_sheet.dart";
import "document_flow_footer.dart";

/// A manual entry board as a step in a sheet: its [ManualEntryLayout] in a
/// [Form] with Continue (enabled with [onContinue]); the sheet's bar has the
/// title, back and close. A tap outside the fields closes the keyboard.
class ManualEntryScaffold extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback onChanged;
  final String titleKey;
  final String explanationKey;
  final String tipKey;
  final List<Widget> fields;
  final VoidCallback? onContinue;

  const ManualEntryScaffold({
    super.key,
    required this.formKey,
    required this.onChanged,
    required this.titleKey,
    required this.explanationKey,
    required this.tipKey,
    required this.fields,
    required this.onContinue,
  });

  /// The buttons: the sheet's close button is the way out.
  List<Widget> get _sheetButtons => [
    DocumentFlowButton(
      key: DocumentFlowButton.primaryKey,
      labelKey: "ui.continue",
      onPressed: onContinue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final split = useSheetColumns(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DocumentStepScaffold(
        body: SizedBox(
          height: .infinity,
          child: documentScroll(
            context,
            Form(
              key: formKey,
              onChanged: onChanged,
              child: SafeArea(
                // Sideways the sheet's columns keep clear of the bottom.
                bottom: !split,
                child: Padding(
                  padding: split
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(
                          YiviSpace.x16,
                          YiviSpace.x16,
                          YiviSpace.x16,
                          YiviSpace.x24,
                        ),
                  child: ManualEntryLayout(
                    actions: split
                        ? DocumentFlowFooter.sheetActions(
                            context,
                            _sheetButtons,
                          )
                        : null,
                    titleKey: titleKey,
                    explanationKey: explanationKey,
                    tipKey: tipKey,
                    fields: fields,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Sideways the buttons are in the left column.
        bottomBar: split ? null : DocumentFlowFooter(buttons: _sheetButtons),
      ),
    );
  }
}

/// The body of the manual entry boards: a heading, the explanation, the
/// fields on one white card and a tip about where to find the details.
class ManualEntryLayout extends StatelessWidget {
  const ManualEntryLayout({
    required this.titleKey,
    required this.explanationKey,
    required this.tipKey,
    required this.fields,
    this.actions,
    super.key,
  });

  final String titleKey;
  final String explanationKey;
  final String tipKey;
  final List<Widget> fields;

  /// The buttons, in the left column of a sheet held sideways
  /// ([useSheetColumns]); elsewhere the screen's own bar has them.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    if (useSheetColumns(context)) return _split(context, palette);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x4,
            YiviSpace.x8,
            YiviSpace.x4,
            0,
          ),
          child: TranslatedText(
            titleKey,
            isHeader: true,
            style: palette.titleStep,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x4,
            YiviSpace.x8,
            YiviSpace.x4,
            0,
          ),
          child: TranslatedText(
            explanationKey,
            style: palette.body(16).copyWith(height: 24 / 16),
          ),
        ),
        SurfaceCard(
          margin: const EdgeInsets.only(top: YiviSpace.x24),
          padding: const EdgeInsets.all(YiviSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x16,
            children: fields,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: YiviSpace.x12),
          child: DocumentTipBox(textKey: tipKey),
        ),
      ],
    );
  }

  /// A sheet held sideways: the heading, the explanation, the tip and the
  /// button at the left (only the heading and the button while the keyboard
  /// is up), the fields on their card at the right; three fields as the
  /// first across, the other two (the dates) side by side.
  Widget _split(BuildContext context, YiviPalette palette) {
    final keyboard = SheetSplit.keyboardUp(context);
    final card = SurfaceCard(
      padding: const EdgeInsets.all(YiviSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x12,
        children: fields.length == 3
            ? [
                fields[0],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: YiviSpace.x12,
                  children: [
                    Expanded(child: fields[1]),
                    Expanded(child: fields[2]),
                  ],
                ),
              ]
            : fields,
      ),
    );
    return SheetSplit(
      start: [
        TranslatedText(
          titleKey,
          isHeader: true,
          style: documentSplitHeadingStyle(palette),
        ),
        if (!keyboard) ...[
          TranslatedText(
            explanationKey,
            style: documentSplitBodyStyle(palette),
          ),
          DocumentTipBox(textKey: tipKey),
        ],
      ],
      end: card,
      actions: actions,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            YiviSpace.x4,
            0,
            YiviSpace.x4,
            YiviSpace.x8,
          ),
          child: Text(label, style: fieldLabelStyle(context)),
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
    hintStyle: palette
        .body(useSheetColumns(context) ? 14 : 16)
        .copyWith(color: palette.secondaryText),
    // In a sheet held sideways two fields share a row: a little tighter, so
    // "YYYY-MM-DD" fits.
    contentPadding: EdgeInsets.symmetric(
      horizontal: useSheetColumns(context) ? 12 : 16,
      vertical: 15,
    ),
    suffixIcon: suffixIcon,
    suffixIconConstraints: BoxConstraints(
      minHeight: 48,
      minWidth: useSheetColumns(context) ? 40 : 48,
    ),
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
