import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/sheet/sheet_layout.dart";
import "../../../widgets/surfaces/surface_card.dart";
import "../../../widgets/text/translated_text.dart";
import "document_step_in_sheet.dart";
import "document_translation_keys.dart";
import "widgets/document_flow_footer.dart";
import "widgets/document_instruction_illustration.dart";
import "widgets/document_scan_scene.dart";

/// Shown before the MRZ camera: how to hold the document. [onStart] opens the
/// camera; the sheet's bar has the title, back and close.
class DocumentInstructionScreen extends StatelessWidget {
  const DocumentInstructionScreen({
    required this.documentType,
    required this.onStart,
    super.key,
  });

  /// The picture's card fits the scene it shows.
  static const _pictureSize = DocumentScanScene.size;

  final DocumentType documentType;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final keys = documentType.instructionKey;

    // The picture on a white card.
    final picture = SurfaceCard(
      key: const Key("document_instruction_picture"),
      width: _pictureSize.width,
      height: _pictureSize.height,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Semantics(
        image: true,
        label: context.tr("$keys.image_alt"),
        child: DocumentInstructionIllustration(documentType: documentType),
      ),
    );
    List<Widget> words(TextAlign align, {double top = 28, double size = 24}) =>
        [
          Padding(
            // In a sheet's column flush with the words under it.
            padding: EdgeInsets.fromLTRB(
              top == 0 ? 0 : 8,
              top,
              top == 0 ? 0 : 8,
              0,
            ),
            child: TranslatedText(
              "$keys.title",
              textAlign: align,
              isHeader: true,
              style: palette
                  .display(size, weight: FontWeight.w700)
                  .copyWith(height: (size + 6) / size, color: palette.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x12),
            child: TranslatedText(
              "$keys.body",
              textAlign: align,
              style: palette.body(16).copyWith(height: 24 / 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x16),
            child: DocumentTipBox(textKey: "$keys.tip"),
          ),
        ];
    final buttons = [
      DocumentFlowButton(
        key: DocumentFlowButton.primaryKey,
        labelKey: "document_flow.start",
        onPressed: onStart,
      ),
    ];
    // In a sheet held sideways, as on every step of the document flows: the
    // words and Start at the left, the picture at the right.
    if (useSheetColumns(context)) {
      return DocumentStepScaffold.split(
        SheetSplit(
          endFills: true,
          // The title and what to do at the left; the tip under the
          // picture, where the column has room for it.
          start: words(TextAlign.start, top: 0, size: 22).take(2).toList(),
          end: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x12,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _pictureSize.width / _pictureSize.height,
                    child: FittedBox(child: picture),
                  ),
                ),
              ),
              DocumentTipBox(textKey: "$keys.tip"),
            ],
          ),
          actions: DocumentFlowFooter.sheetActions(context, buttons),
        ),
      );
    }
    return DocumentStepScaffold(
      body: SingleChildScrollView(
        // 24 below the floating app bar and from the sides, as on the board.
        padding: const EdgeInsets.fromLTRB(
          YiviSpace.x24,
          YiviSpace.x24,
          YiviSpace.x24,
          YiviSpace.x24,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .center,
            children: [picture, ...words(TextAlign.center)],
          ),
        ),
      ),
      bottomBar: DocumentFlowFooter(buttons: buttons),
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
      padding: const EdgeInsets.symmetric(
        horizontal: YiviSpace.x16,
        vertical: YiviSpace.x12,
      ),
      decoration: BoxDecoration(
        color: palette.outline,
        borderRadius: YiviCorners.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: .start,
        spacing: YiviSpace.x12,
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
