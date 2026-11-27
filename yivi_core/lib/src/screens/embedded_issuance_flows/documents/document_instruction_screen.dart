import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/theme.dart";
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
    final keys = documentType.instructionKey;

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      appBar: IrmaAppBar(
        titleTranslationKey: documentType.scanTitleKey,
        hasBorder: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: .all(theme.mediumSpacing),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: theme.mediumSpacing,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _pictureWidth),
                  child: AspectRatio(
                    aspectRatio: _pictureWidth / _pictureHeight,
                    child: Semantics(
                      image: true,
                      label: FlutterI18n.translate(context, "$keys.image_alt"),
                      child: DocumentInstructionAnimation(
                        documentType: documentType,
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      height: 26 / 18,
                    ),
                  ),
                  TranslatedText("$keys.body", textAlign: .center),
                  Padding(
                    padding: .symmetric(
                      horizontal: theme.tinySpacing,
                      vertical: theme.tinySpacing / 2,
                    ),
                    child: TranslatedText(
                      "$keys.tip",
                      textAlign: .center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 20 / 14,
                        color: theme.neutralExtraDark,
                      ),
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
