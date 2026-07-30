import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../theme/theme.dart";
import "../../../widgets/collapsible.dart";
import "../../../widgets/irma_markdown.dart";

class SchemalessAddDataQuestions extends StatelessWidget {
  const SchemalessAddDataQuestions({
    required this.faq,
    required this.parentScrollController,
    this.inDisclosure = false,
  });

  final Faq faq;
  final ScrollController parentScrollController;
  final bool inDisclosure;

  Widget _buildCollapsible(
    BuildContext context,
    String headerTranslationKey,
    String bodyText, {
    bool initiallyExpanded = false,
    bool showDisclosureInfo = false,
  }) {
    final theme = IrmaTheme.of(context);

    String markdown = "";
    if (showDisclosureInfo) {
      markdown =
          '${FlutterI18n.translate(context, 'data.add.details.disclosure_info_markdown')}\n\n';
    }
    markdown = markdown + bodyText.replaceAll("\\n", "\n\n");

    return Padding(
      padding: .symmetric(vertical: theme.tinySpacing),
      child: Collapsible(
        initiallyExpanded: initiallyExpanded,
        header: FlutterI18n.translate(context, headerTranslationKey),
        parentScrollController: parentScrollController,
        content: SizedBox(width: .infinity, child: IrmaMarkdown(markdown)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = faq.content ?? "";
    final purpose = faq.purpose ?? "";
    final howTo = faq.howTo ?? "";
    return Column(
      mainAxisAlignment: .start,
      crossAxisAlignment: .start,
      children: [
        if (content.isNotEmpty)
          _buildCollapsible(
            context,
            "data.add.details.content_question",
            content,
            initiallyExpanded: true,
            showDisclosureInfo: inDisclosure,
          ),
        if (purpose.isNotEmpty)
          _buildCollapsible(
            context,
            "data.add.details.purpose_question",
            purpose,
            initiallyExpanded: content.isEmpty,
          ),
        if (howTo.isNotEmpty)
          _buildCollapsible(
            context,
            "data.add.details.howto_question",
            howTo,
            initiallyExpanded: content.isEmpty && purpose.isEmpty,
          ),
      ],
    );
  }
}
