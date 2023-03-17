import 'package:flutter/material.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_type_card.dart';

class CredentialCategoryList extends StatelessWidget {
  final String categoryName;
  final List<CredentialType> credentialTypes;
  final List<CredentialType>? obtainedCredentialTypes;
  final Function(CredentialType credType)? onCredentialTypeTap;

  const CredentialCategoryList({
    required this.categoryName,
    required this.credentialTypes,
    this.obtainedCredentialTypes,
    this.onCredentialTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: theme.defaultSpacing),
        Semantics(
          header: true,
          child: Text(
            categoryName,
            style: theme.textTheme.headline4,
          ),
        ),
        SizedBox(height: theme.smallSpacing),
        ...credentialTypes.map(
          (credType) => IrmaCredentialTypeCard(
            credType: credType,
            checked: obtainedCredentialTypes?.contains(credType) ?? false,
            onTap: () => onCredentialTypeTap?.call(
              credType,
            ),
          ),
        )
      ],
    );
  }
}
