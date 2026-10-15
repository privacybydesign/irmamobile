import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/document_flow_footer.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/translated_text.dart";
import "document_translation_keys.dart";
import "widgets/document_instruction_animation.dart";

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
    final theme = IrmaTheme.of(context);
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
        // 16 around and 16 inside the stage keep the picture at its 320.
        padding: .all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: theme.mediumSpacing,
            children: [
              // The animation on a tinted, rounded stage.
              Container(
                padding: .all(theme.defaultSpacing),
                decoration: ShapeDecoration(
                  color: palette.tint,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _pictureWidth),
                    child: AspectRatio(
                      aspectRatio: _pictureWidth / _pictureHeight,
                      child: Semantics(
                        image: true,
                        label: FlutterI18n.translate(
                          context,
                          "$keys.image_alt",
                        ),
                        child: DocumentInstructionAnimation(
                          documentType: documentType,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                spacing: theme.smallSpacing + theme.tinySpacing,
                children: [
                  TranslatedText(
                    "$keys.title",
                    textAlign: .center,
                    isHeader: true,
                    style: palette
                        .display(22, weight: FontWeight.w700)
                        .copyWith(height: 30 / 22),
                  ),
                  TranslatedText(
                    "$keys.body",
                    textAlign: .center,
                    style: palette.body(16).copyWith(height: 24 / 16),
                  ),
                  // The tip on an info card.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: .start,
                      spacing: 12,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: palette.link,
                        ),
                        Expanded(
                          child: TranslatedText(
                            "$keys.tip",
                            style: palette
                                .body(14)
                                .copyWith(
                                  height: 20 / 14,
                                  color: palette.heading,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
