import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../theme/theme.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
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

  final DocumentType documentType;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final keys = documentType.instructionKey;

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: IrmaAppBar(titleTranslationKey: documentType.scanTitleKey),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: .all(theme.defaultSpacing),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: DocumentInstructionAnimation(
                    documentType: documentType,
                  ),
                ),
              ),
              SizedBox(height: theme.largeSpacing),
              TranslatedText("$keys.title", style: theme.bodyHeading),
              SizedBox(height: theme.defaultSpacing),
              TranslatedText("$keys.body"),
              SizedBox(height: theme.defaultSpacing),
              Container(
                padding: .all(theme.defaultSpacing),
                decoration: BoxDecoration(
                  color: theme.surfaceSecondary,
                  borderRadius: theme.borderRadius,
                ),
                child: TranslatedText("$keys.tip"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: IrmaBottomBar(
        primaryButtonLabel: "document_flow.start",
        onPrimaryPressed: onStart,
        secondaryButtonLabel: "ui.cancel",
        onSecondaryPressed: onCancel,
      ),
    );
  }
}
