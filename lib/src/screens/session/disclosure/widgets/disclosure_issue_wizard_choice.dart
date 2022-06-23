import 'package:flutter/material.dart';

import '../../../../models/attributes.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/translated_text.dart';
import '../models/disclosure_credential.dart';
import '../models/template_disclosure_credential.dart';

class DisclosureIssueWizardChoice extends StatelessWidget {
  final DisCon<DisclosureCredential> choice;
  final bool isActive;
  final int selectedConIndex;
  final Function(int conIndex) onChoiceUpdated;

  const DisclosureIssueWizardChoice({
    required this.choice,
    required this.onChoiceUpdated,
    required this.selectedConIndex,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(theme.smallSpacing),
          child: TranslatedText(
            'disclosure_permission.choose',
            style: theme.themeData.textTheme.headline5,
            textAlign: TextAlign.start,
          ),
        ),
        for (var i = 0; i < choice.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(bottom: theme.tinySpacing),
            child: Column(
              children: choice[i]
                  .map(
                    (credential) => GestureDetector(
                      onTap: () => isActive ? onChoiceUpdated(i) : null,
                      child: IrmaCredentialCard(
                        padding: EdgeInsets.only(
                          left: theme.tinySpacing,
                          right: theme.tinySpacing,
                          //Only add top padding if this is the first item
                          top: credential == choice[i].first ? theme.tinySpacing : 0,
                          //Only add bottom padding if this is the last item.
                          bottom: credential == choice[i].last ? theme.tinySpacing : 0,
                        ),
                        credentialInfo: credential,
                        attributes: credential.attributes,
                        compareTo: credential is TemplateDisclosureCredential ? credential.attributes : null,
                        headerTrailing: credential == choice[i].first
                            ? Radio(
                                value: i,
                                groupValue: selectedConIndex,
                                onChanged: null, //We use the onTap wrapping GestureDetector
                                fillColor: MaterialStateColor.resolveWith((states) => theme.themeData.primaryColor),
                              )
                            : null,
                        style: isActive
                            ? i == selectedConIndex
                                ? IrmaCardStyle.highlighted
                                : IrmaCardStyle.outlined
                            : IrmaCardStyle.normal,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ]
      ],
    );
  }
}
