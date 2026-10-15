import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(
        titleTranslationKey: documentType.scanTitleKey,
        hasBorder: false,
      ),
      body: SingleChildScrollView(
        // 24 below the floating app bar and from the sides, as on the board.
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .center,
            children: [
              // The picture on a white card.
              Container(
                key: const Key("document_instruction_picture"),
                width: _pictureWidth,
                height: _pictureHeight,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: palette.surface,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
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
                  child: DocumentInstructionIllustration(
                    documentType: documentType,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 28, 8, 0),
                child: TranslatedText(
                  "$keys.title",
                  textAlign: .center,
                  isHeader: true,
                  style: palette
                      .display(22, weight: FontWeight.w700)
                      .copyWith(height: 30 / 22, color: palette.heading),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TranslatedText(
                  "$keys.body",
                  textAlign: .center,
                  style: palette.body(16).copyWith(height: 24 / 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: DocumentTipBox(textKey: "$keys.tip"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DocumentFlowFooter(
        buttons: [
          DocumentFlowButton(
            key: DocumentFlowButton.primaryKey,
            labelKey: "document_flow.start",
            onPressed: onStart,
          ),
          DocumentFlowButton(
            key: DocumentFlowButton.secondaryKey,
            labelKey: "document_flow.cancel",
            onPressed: onCancel,
            style: .outline,
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(20),
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
