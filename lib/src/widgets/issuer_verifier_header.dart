import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_avatar.dart';

class IssuerVerifierHeader extends StatelessWidget {
  final String title;
  final TextStyle? titleTextStyle;
  final Image? image;

  const IssuerVerifierHeader({
    required this.title,
    this.titleTextStyle,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IrmaAvatar(
          size: 46,
          logoImage: image,
          initials: title != '' ? title[0] : null,
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
