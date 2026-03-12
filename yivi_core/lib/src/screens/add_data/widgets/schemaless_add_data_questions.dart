import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/translated_value.dart";
import "../../../theme/theme.dart";
import "../../../util/language.dart";
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
    TranslatedValue bodyText, {
    bool initiallyExpanded = false,
    bool showDisclosureInfo = false,
  }) {
    final theme = IrmaTheme.of(context);

    String markdown = "";
    if (showDisclosureInfo) {
      markdown =
          '${FlutterI18n.translate(context, 'data.add.details.disclosure_info_markdown')}\n\n';
    }
    markdown =
        markdown + getTranslation(context, bodyText).replaceAll("\\n", "\n\n");

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
    return Column(
      mainAxisAlignment: .start,
      crossAxisAlignment: .start,
      children: [
        if (faq.content.isNotEmpty)
          _buildCollapsible(
            context,
            "data.add.details.content_question",
            faq.content,
            initiallyExpanded: true,
            showDisclosureInfo: inDisclosure,
          ),
        if (faq.purpose.isNotEmpty)
          _buildCollapsible(
            context,
            "data.add.details.purpose_question",
            faq.purpose,
            initiallyExpanded: faq.content.isEmpty,
          ),
        if (faq.howTo.isNotEmpty)
          _buildCollapsible(
            context,
            "data.add.details.howto_question",
            faq.howTo,
            initiallyExpanded: faq.content.isEmpty && faq.purpose.isEmpty,
          ),
      ],
    );
  }
}
