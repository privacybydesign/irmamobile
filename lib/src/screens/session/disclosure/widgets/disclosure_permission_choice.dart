import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import '../../../../util/con_dis_con.dart';
import '../../../../widgets/credential_card/irma_credential_card.dart';
import '../../../../widgets/radio_indicator.dart';
import '../models/choosable_disclosure_credential.dart';
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

  Widget _buildChoiceOption(BuildContext context, MapEntry<int, Con<DisclosureCredential>> option) {
    final theme = IrmaTheme.of(context);
    final isDisabled = option.value.any((cred) => cred is TemplateDisclosureCredential && !cred.obtainable);

    return Padding(
      padding: EdgeInsets.all(theme.tinySpacing),
      child: Semantics(
        button: true,
        child: Column(
          children: option.value
              .map(
                (credential) => GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () {
                          if (isActive) {
                            onChoiceUpdated(option.key);
                          }
                        },
                  child: IrmaCredentialCard(
                    credentialFormat:
                        credential is ChoosableDisclosureCredential ? credential.credentialFormat : 'unknown',
                    padding: EdgeInsets.zero,
                    credentialView: credential,
                    compareTo: credential is TemplateDisclosureCredential ? credential.attributes : null,
                    disabled: isDisabled,
                    headerTrailing: credential == option.value.first
                        ? RadioIndicator(
                            isSelected: option.key == selectedConIndex,
                          )
                        : null,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in choice.entries) _buildChoiceOption(context, entry),
        ],
      );
}
