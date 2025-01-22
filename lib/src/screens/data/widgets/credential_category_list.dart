import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/irma_configuration.dart';
import '../../../theme/theme.dart';
import '../../../widgets/credential_card/irma_credential_type_card.dart';

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
    final theme = IrmaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: theme.defaultSpacing),
        Semantics(
          header: true,
          child: Text(
            categoryName,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        SizedBox(height: theme.smallSpacing),
        ...credentialTypes.map(
          (credType) => Semantics(
            button: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: theme.smallSpacing),
              child: IrmaCredentialTypeCard(
                credType: credType,
                checked: obtainedCredentialTypes?.contains(credType) ?? false,
                trailingIcon: credentialTypeTrailingIcon,
                onTap: () => onCredentialTypeTap?.call(
                  credType,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
