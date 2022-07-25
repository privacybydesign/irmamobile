import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/translated_value.dart';
import '../../../theme/theme.dart';
import '../../../util/language.dart';
import '../../../widgets/collapsible.dart';

class AddDataQuestions extends StatelessWidget {
  const AddDataQuestions({
    required this.credentialType,
    required this.parentScrollController,
  });

  final CredentialType credentialType;
  final ScrollController parentScrollController;

  Widget _buildCollapsible(BuildContext context, String headerTranslationKey, TranslatedValue bodyText) {
    final theme = IrmaTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
      child: Collapsible(
        header: FlutterI18n.translate(context, headerTranslationKey),
        parentScrollController: parentScrollController,
        content: SizedBox(
          width: double.infinity,
          child: Text(
            getTranslation(context, bodyText).replaceAll('\\n', '\n'),
            style: theme.textTheme.bodyText2,
            textAlign: TextAlign.left,
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
        if (credentialType.faqPurpose.isNotEmpty)
          _buildCollapsible(context, 'data.add.details.purpose_question', credentialType.faqPurpose),
        if (credentialType.faqContent.isNotEmpty)
          _buildCollapsible(context, 'data.add.details.content_question', credentialType.faqContent),
        if (credentialType.faqHowto.isNotEmpty)
          _buildCollapsible(context, 'data.add.details.howto_question', credentialType.faqHowto),
      ],
    );
  }
}
