import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'credential_card_icon.dart';

enum CredentialHeaderType { normal, template, success, error }

class IrmaCredentialCardHeader extends StatelessWidget {
  final String? logo;
  final String credentialName;
  final String? issuerName;
  final CredentialHeaderType type;

  const IrmaCredentialCardHeader({
    this.logo,
    required this.credentialName,
    this.issuerName,
    this.type = CredentialHeaderType.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Row(
      children: [
        CredentialCardIcon(
          type: type,
          logo: logo,
        ),
        SizedBox(
          width: IrmaTheme.of(context).smallSpacing,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                credentialName,
                style: theme.themeData.textTheme.bodyText1,
              ),
              Text(
                issuerName ?? '',
                overflow: TextOverflow.ellipsis,
                style: theme.themeData.textTheme.caption,
              )
            ],
          ),
        ),
      ],
    );
  }
}
