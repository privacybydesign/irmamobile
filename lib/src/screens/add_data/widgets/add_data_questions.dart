import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/translated_value.dart';
import '../../../theme/theme.dart';
import '../../../util/language.dart';
import '../../../widgets/collapsible.dart';
import '../../../widgets/irma_markdown.dart';

class AddDataQuestions extends StatelessWidget {
  const AddDataQuestions({
    required this.credentialType,
    required this.parentScrollController,
    this.inDisclosure = false,
  });

  final CredentialType credentialType;
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

    String markdown = '';
    if (showDisclosureInfo) {
      markdown = '${FlutterI18n.translate(context, 'data.add.details.disclosure_info_markdown')}\n\n';
    }
    markdown = markdown +
        getTranslation(context, bodyText).replaceAll(
          '\\n',
          '\n\n',
        );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
      child: Collapsible(
        initiallyExpanded: initiallyExpanded,
        header: FlutterI18n.translate(context, headerTranslationKey),
        parentScrollController: parentScrollController,
        content: SizedBox(
          width: double.infinity,
          child: IrmaMarkdown(
            markdown,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (credentialType.faqContent.isNotEmpty)
          _buildCollapsible(
            context,
            'data.add.details.content_question',
            credentialType.faqContent,
            initiallyExpanded: true,
            showDisclosureInfo: inDisclosure,
          ),
        if (credentialType.faqPurpose.isNotEmpty)
          _buildCollapsible(
            context,
            'data.add.details.purpose_question',
            credentialType.faqPurpose,
            initiallyExpanded: credentialType.faqContent.isEmpty,
          ),
        if (credentialType.faqHowto.isNotEmpty)
          _buildCollapsible(
            context,
            'data.add.details.howto_question',
            credentialType.faqHowto,
            initiallyExpanded: credentialType.faqContent.isEmpty && credentialType.faqPurpose.isEmpty,
          ),
      ],
    );
  }
}
