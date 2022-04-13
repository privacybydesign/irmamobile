import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'credential_card_icon.dart';

enum CredentialHeaderType { normal, template, success, error }

class IrmaCredentialCardHeader extends StatelessWidget {
  final String? logo;
  final String title;
  final String? subtitle;
  final CredentialHeaderType type;

  const IrmaCredentialCardHeader({
    this.logo,
    required this.title,
    this.subtitle,
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
                title,
                style: theme.themeData.textTheme.bodyText1,
              ),
              Text(
                subtitle ?? '',
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
