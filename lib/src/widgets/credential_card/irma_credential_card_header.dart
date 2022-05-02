import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../irma_card.dart';
import 'credential_card_icon.dart';

class IrmaCredentialCardHeader extends StatelessWidget {
  final String? logo;
  final String title;
  final String? subtitle;
  final IrmaCardStyle style;

  const IrmaCredentialCardHeader({
    this.logo,
    required this.title,
    this.subtitle,
    this.style = IrmaCardStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Row(
      children: [
        CredentialCardIcon(
          style: style,
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
