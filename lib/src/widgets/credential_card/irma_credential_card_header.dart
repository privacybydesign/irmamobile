import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../translated_text.dart';

class IrmaCredentialCardHeader extends StatelessWidget {
  final String title;
  final String? logo;
  final String? subtitle;
  final Widget? trailing;
  final bool isExpired;
  final bool isExpiringSoon;
  final bool isRevoked;

  const IrmaCredentialCardHeader({
    required this.title,
    this.logo,
    this.subtitle,
    this.trailing,
    this.isExpiringSoon = false,
    this.isExpired = false,
    this.isRevoked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          radius: 20,
          child: logo != null && logo != ''
              ? SizedBox(
                  height: 26,
                  child: Image.file(
                    File(logo!),
                    excludeFromSemantics: true,
                  ),
                )
              : Container(),
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isExpired)
                TranslatedText(
                  'credential.expired',
                  style: theme.themeData.textTheme.headline4!.copyWith(
                    color: theme.error,
                  ),
                )
              else if (isExpiringSoon)
                TranslatedText(
                  'credential.about_to_expire',
                  style: theme.themeData.textTheme.headline4!.copyWith(
                    color: theme.warning,
                  ),
                )
              else if (isRevoked)
                TranslatedText(
                  'credential.revoked',
                  style: theme.themeData.textTheme.headline4!.copyWith(
                    color: theme.warning,
                  ),
                ),
              Text(
                title,
                style: theme.themeData.textTheme.bodyText1,
              ),
              Text(
                subtitle ?? '',
                style: theme.themeData.textTheme.caption!.copyWith(
                  color: theme.neutralDark,
                ),
              )
            ],
          ),
        ),
        if (trailing != null && !isExpired && !isRevoked) ...[
          SizedBox(width: theme.smallSpacing),
          trailing!,
        ],
      ],
    );
  }
}
