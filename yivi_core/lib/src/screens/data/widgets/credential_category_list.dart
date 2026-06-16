import "package:flutter/material.dart";

import "../../../models/irma_configuration.dart";
import "../../../theme/theme.dart";
import "../../../widgets/credential_card/irma_credential_type_card.dart";
import "../../../widgets/section_header.dart";

class CredentialCategoryList extends StatelessWidget {
  final String categoryName;
  final List<CredentialType> credentialTypes;
  final List<CredentialType>? obtainedCredentialTypes;
  final Function(CredentialType credType)? onCredentialTypeTap;
  final IconData? credentialTypeTrailingIcon;

  const CredentialCategoryList({
    required this.categoryName,
    required this.credentialTypes,
    this.obtainedCredentialTypes,
    this.onCredentialTypeTap,
    this.credentialTypeTrailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.yivi.spacing.base),
        SectionHeader.text(categoryName),
        SizedBox(height: context.yivi.spacing.small),
        ...credentialTypes.map(
          (credType) => Semantics(
            button: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.yivi.spacing.small),
              child: IrmaCredentialTypeCard(
                credType: credType,
                checked: obtainedCredentialTypes?.contains(credType) ?? false,
                trailingIcon: credentialTypeTrailingIcon,
                onTap: () => onCredentialTypeTap?.call(credType),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
