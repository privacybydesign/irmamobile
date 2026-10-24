import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";
import "../../../../widgets/document_flow_footer.dart";
import "../../../../widgets/glass/sheet_action_row.dart";
import "../../../../widgets/irma_bottom_bar.dart";
import "../../../../widgets/surface_card.dart";
import "../../../../widgets/translated_text.dart";
import "../document_instruction_screen.dart";
import "../document_step_in_sheet.dart";

/// A manual entry board: its [ManualEntryLayout] in a [Form] with
/// Continue (enabled with [onContinue]) and Cancel, full-screen or as a
/// step in a sheet (whose close button is then the way out). A tap outside
/// the fields closes the keyboard.
class ManualEntryScaffold extends StatelessWidget {
  final String appBarTitleKey;
  final GlobalKey<FormState> formKey;
  final VoidCallback onChanged;
  final String titleKey;
  final String explanationKey;
  final String tipKey;
  final List<Widget> fields;
  final VoidCallback? onContinue;
  final VoidCallback onCancel;

  const ManualEntryScaffold({
    super.key,
    required this.appBarTitleKey,
    required this.formKey,
    required this.onChanged,
    required this.titleKey,
    required this.explanationKey,
    required this.tipKey,
    required this.fields,
    required this.onContinue,
    required this.onCancel,
  });

  /// The buttons in a sheet: its close button is the way out.
  List<Widget> get _sheetButtons => [
    DocumentFlowButton(
      key: DocumentFlowButton.primaryKey,
      labelKey: "ui.continue",
      onPressed: onContinue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      // In a sheet its bar has the title, back and close.
      child: DocumentStepScaffold(
        titleKey: appBarTitleKey,
        body: SizedBox(
          height: .infinity,
          child: documentScroll(
            context,
            Form(
              key: formKey,
              onChanged: onChanged,
              child: SafeArea(
                // Sideways the sheet's columns keep clear of the bottom.
                bottom: !documentStepSplit(context),
                child: Padding(
                  padding: documentStepSplit(context)
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: ManualEntryLayout(
                    actions: documentStepSplit(context)
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
        // In a sheet, the sheet's own buttons; its close button is the way out.
        bottomBar: documentStepSplit(context)
            ? null
            : DocumentStepInSheet.of(context)
            ? DocumentFlowFooter(buttons: _sheetButtons)
            : IrmaBottomBar(
                primaryButtonLabel: "ui.continue",
                onPrimaryPressed: onContinue,
                secondaryButtonLabel: "ui.cancel",
                onSecondaryPressed: onCancel,
              ),
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
  /// ([documentStepSplit]); elsewhere the screen's own bar has them.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    if (documentStepSplit(context)) return _split(context, palette);
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
        SurfaceCard(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(16),
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

  /// A sheet held sideways: the heading, the explanation, the tip and the
  /// button at the left (only the heading and the button while the keyboard
  /// is up), the fields on their card at the right; three fields as the
  /// first across, the other two (the dates) side by side.
  Widget _split(BuildContext context, YiviPalette palette) {
    final keyboard = SheetSplit.keyboardUp(context);
    final card = SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: fields.length == 3
            ? [
                fields[0],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
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
      startWidth: SheetSplit.wideWidth,
      start: [
        TranslatedText(
          titleKey,
          isHeader: true,
          style: palette
              .display(20, weight: FontWeight.w700)
              .copyWith(height: 28 / 20, color: palette.heading),
        ),
        if (!keyboard) ...[
          TranslatedText(
            explanationKey,
            style: palette.body(14.5).copyWith(height: 21 / 14.5),
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
    hintStyle: palette
        .body(documentStepSplit(context) ? 14 : 16)
        .copyWith(color: palette.secondaryText),
    // In a sheet held sideways two fields share a row: a little tighter, so
    // "YYYY-MM-DD" fits.
    contentPadding: EdgeInsets.symmetric(
      horizontal: documentStepSplit(context) ? 12 : 16,
      vertical: 15,
    ),
    suffixIcon: suffixIcon,
    suffixIconConstraints: BoxConstraints(
      minHeight: 48,
      minWidth: documentStepSplit(context) ? 40 : 48,
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
