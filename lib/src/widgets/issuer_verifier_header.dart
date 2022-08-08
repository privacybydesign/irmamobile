import 'package:flutter/material.dart';

import '../theme/theme.dart';

class IssuerVerifierHeader extends StatelessWidget {
  final String title;
  final TextStyle? titleTextStyle;
  final String? logo;
  final Image? image;

  const IssuerVerifierHeader({
    required this.title,
    this.titleTextStyle,
    this.logo,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          radius: 24,
          child: image,
        ),
        SizedBox(
          width: theme.smallSpacing,
        ),
        Flexible(
          child: Text(
            title,
            style: titleTextStyle ?? theme.textTheme.bodyText1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
