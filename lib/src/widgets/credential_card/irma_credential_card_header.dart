import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class IrmaCredentialCardHeader extends StatelessWidget {
  final String? logo;
  final String? title;
  final String? subtitle;

  const IrmaCredentialCardHeader({this.logo, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Row(
      children: [
        SizedBox(
            width: 40,
            child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                radius: 18,
                child: Builder(builder: (context) {
                  if (logo != null && logo != '') {
                    return SizedBox(height: 24, child: Image.file(File(logo!), excludeFromSemantics: true));
                  }
                  return Container();
                }))),
        SizedBox(
          width: IrmaTheme.of(context).smallSpacing,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? '',
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
