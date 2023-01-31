import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_avatar.dart';
import 'irma_card.dart';

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

    return IrmaCard(
      style: IrmaCardStyle.flat,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.all(
        theme.smallSpacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IrmaAvatar(
            size: 52,
            logoImage: image,
            initials: title != '' ? title[0] : null,
          ),
          SizedBox(
            width: theme.smallSpacing,
          ),
          Flexible(
            child: Text(
              title,
              style: titleTextStyle ??
                  theme.textTheme.bodyText1!.copyWith(
                    color: theme.neutralExtraDark,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
