import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "widgets/document_instruction_illustration.dart";

/// Shown before the MRZ camera: how to hold the document. [onStart] opens the
/// camera, [onCancel] leaves the flow.
class DocumentInstructionScreen extends StatelessWidget {
  const DocumentInstructionScreen({
    required this.documentType,
    required this.onStart,
    required this.onCancel,
    super.key,
  });

  static const double _pictureWidth = 320;
  static const double _pictureHeight = 256;

  final DocumentType documentType;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final keys = documentType.instructionKey;
    // In a sheet: its bar has the title, back and close; no Cancel here.
    final inSheet = DocumentStepInSheet.of(context);

    // The picture on a white card.
    final picture = Container(
      key: const Key("document_instruction_picture"),
      width: _pictureWidth,
      height: _pictureHeight,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Semantics(
        image: true,
        label: FlutterI18n.translate(context, "$keys.image_alt"),
        child: DocumentInstructionIllustration(documentType: documentType),
      ),
    );
    List<Widget> words(TextAlign align, {double top = 28, double size = 22}) =>
        [
          Padding(
            padding: EdgeInsets.fromLTRB(
              top == 0 ? 4 : 8,
              top,
              top == 0 ? 4 : 8,
              0,
            ),
            child: TranslatedText(
              "$keys.title",
              textAlign: align,
              isHeader: true,
              style: palette
                  .display(size, weight: FontWeight.w700)
                  .copyWith(height: (size + 8) / size, color: palette.heading),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TranslatedText(
              "$keys.body",
              textAlign: align,
              style: palette.body(16).copyWith(height: 24 / 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: DocumentTipBox(textKey: "$keys.tip"),
          ),
        ];
    final buttons = [
      DocumentFlowButton(
        key: DocumentFlowButton.primaryKey,
        labelKey: "document_flow.start",
        onPressed: onStart,
      ),
      if (!inSheet)
        DocumentFlowButton(
          key: DocumentFlowButton.secondaryKey,
          labelKey: "document_flow.cancel",
          onPressed: onCancel,
          style: .secondary,
        ),
    ];
    // In a sheet held sideways: the picture and Start at the left, the
    // words at the right.
    if (documentStepSplit(context)) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SheetSplit(
          start: [
            AspectRatio(
              aspectRatio: _pictureWidth / _pictureHeight,
              child: FittedBox(child: picture),
            ),
          ],
          end: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The title at the top of the column.
              ...words(TextAlign.start, top: 0, size: 20),
            ],
          ),
          actions: DocumentFlowFooter.sheetActions(context, buttons),
        ),
      );
    }
    // A phone held sideways: the picture at the left, the words at the
    // right.
    final landscape = useSheetColumns(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: inSheet ? Colors.transparent : palette.background,
      appBar: inSheet
          ? null
          : IrmaAppBar(
              titleTranslationKey: documentType.scanTitleKey,
              hasBorder: false,
            ),
      body: SingleChildScrollView(
        // 24 below the floating app bar and from the sides, as on the board.
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: SafeArea(
          child: landscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 28,
                  children: [
                    // Smaller: the sheet has little height sideways.
                    SizedBox(
                      width: _pictureWidth * 0.7,
                      height: _pictureHeight * 0.7,
                      child: FittedBox(child: picture),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: words(TextAlign.start),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: .center,
                  children: [picture, ...words(TextAlign.center)],
                ),
        ),
      ),
      bottomNavigationBar: DocumentFlowFooter(buttons: buttons),
    );
  }
}

/// A tip on a light blue box with a light bulb, as on the instruction and
/// manual entry boards.
class DocumentTipBox extends StatelessWidget {
  const DocumentTipBox({required this.textKey, super.key});

  final String textKey;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.outline,
        borderRadius: BorderRadius.circular(YiviCorners.card),
      ),
      child: Row(
        crossAxisAlignment: .start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: palette.noteText,
            ),
          ),
          Expanded(
            child: TranslatedText(
              textKey,
              style: palette
                  .body(14)
                  .copyWith(height: 20 / 14, color: palette.noteText),
            ),
          ),
        ],
      ),
    );
  }
}
