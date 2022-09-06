import 'package:flutter/material.dart';

import '../../../../models/attributes.dart';
import '../../../../theme/theme.dart';
import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/irma_card.dart';
import '../models/disclosure_credential.dart';
import '../models/template_disclosure_credential.dart';

class DisclosurePermissionChoice extends StatelessWidget {
  final Map<int, Con<DisclosureCredential>> choice;
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
        for (final i in choice.keys) ...[
          Padding(
            padding: EdgeInsets.all(theme.tinySpacing),
            child: Column(
              children: choice[i]!
                  .map(
                    (credential) => GestureDetector(
                      onTap: () {
                        if (isActive) {
                          onChoiceUpdated(i);
                        }
                      },
                      child: IrmaCredentialCard(
                        padding: EdgeInsets.zero,
                        credentialInfo: credential,
                        attributes: credential.attributes,
                        compareTo: credential is TemplateDisclosureCredential ? credential.attributes : null,
                        hideFooter: true,
                        headerTrailing: credential == choice[i]!.first
                            ? Radio(
                                value: i,
                                groupValue: selectedConIndex,
                                onChanged: null, //We use the onTap wrapping GestureDetector
                                fillColor: MaterialStateColor.resolveWith((_) => theme.themeData.colorScheme.secondary),
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
