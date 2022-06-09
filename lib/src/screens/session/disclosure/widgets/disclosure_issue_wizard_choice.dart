import 'package:flutter/material.dart';

import '../../../../models/attributes.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/translated_text.dart';
import '../models/template_disclosure_credential.dart';

class DisclosureIssueWizardChoice extends StatefulWidget {
  final DisCon<TemplateDisclosureCredential> choice;
  final bool isActive;

  const DisclosureIssueWizardChoice({
    required this.choice,
    this.isActive = true,
  });

  @override
  State<DisclosureIssueWizardChoice> createState() => _DisclosureIssueWizardChoiceState();
}

class _DisclosureIssueWizardChoiceState extends State<DisclosureIssueWizardChoice> {
  int selectedOptionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(theme.smallSpacing),
          child: TranslatedText(
            'disclosure_permission.issue_wizard.choose',
            style: theme.themeData.textTheme.headline5,
            textAlign: TextAlign.start,
          ),
        ),
        for (var i = 0; i < widget.choice.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(bottom: theme.tinySpacing),
            child: IrmaCredentialsCard(
              headerTrailing: Radio(
                value: i,
                groupValue: selectedOptionIndex,
                onChanged: null, //We use the onTap on the card
                fillColor: MaterialStateColor.resolveWith((states) => theme.themeData.primaryColor),
              ),
              style: widget.isActive
                  ? i == selectedOptionIndex
                      ? IrmaCardStyle.highlighted
                      : IrmaCardStyle.outlined
                  : IrmaCardStyle.normal,
              attributesByCredential: {
                for (var cred in widget.choice[i]) cred: cred.attributes,
              },
              compareToCredentials: widget.choice[i], //Compare to self to highlight the required attribute values
              onTap: widget.isActive ? () => setState(() => selectedOptionIndex = i) : null,
            ),
          ),
        ]
      ],
    );
  }
}
