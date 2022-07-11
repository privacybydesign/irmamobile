import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class IrmaCredentialCardHeader extends StatelessWidget {
  final String title;
  final String? logo;
  final String? subtitle;
  final Widget? trailing;

  const IrmaCredentialCardHeader({
    required this.title,
    this.logo,
    this.subtitle,
    this.trailing,
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
              Text(
                title,
                style: theme.themeData.textTheme.bodyText1,
              ),
              Text(
                subtitle ?? '',
                overflow: TextOverflow.ellipsis,
                style: theme.themeData.textTheme.caption!.copyWith(
                  color: theme.neutralDark,
                ),
              )
            ],
          ),
        ),
        if (trailing != null) trailing!
      ],
    );
  }
}
