import 'package:flutter/material.dart';

import '../../../../models/attributes.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credentials_card.dart';
import '../../../../widgets/irma_card.dart';
import '../../../../widgets/translated_text.dart';
import '../models/disclosure_credential.dart';

class DisclosurePermissionChoice extends StatelessWidget {
  final DisCon<DisclosureCredential> choice;
  final bool isActive;
  final int selectedConIndex;
  final Function(int conIndex) onChoiceUpdated;

  const DisclosurePermissionChoice({
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
            child: IrmaCredentialsCard(
              headerTrailing: Radio(
                value: i,
                groupValue: selectedConIndex,
                onChanged: null, //We use the onTap on the card
                fillColor: MaterialStateColor.resolveWith((states) => theme.themeData.primaryColor),
              ),
              style: isActive
                  ? i == selectedConIndex
                      ? IrmaCardStyle.highlighted
                      : IrmaCardStyle.outlined
                  : IrmaCardStyle.normal,
              attributesByCredential: {
                for (var cred in choice[i]) cred: cred.attributes,
              },
              compareToCredentials: choice[i], //Compare to self to highlight the required attribute values
              onTap: () => isActive ? onChoiceUpdated(i) : null,
            ),
          ),
        ]
      ],
    );
  }
}
