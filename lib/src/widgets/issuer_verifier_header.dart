import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/theme.dart';
import 'irma_avatar.dart';
import 'irma_card.dart';

class IssuerVerifierHeader extends StatelessWidget {
  final String? title;
  final TextStyle? titleTextStyle;
  final Image? image;
  final String? imagePath;
  final Color? backgroundColor;
  final Color? textColor;

  const IssuerVerifierHeader({
    this.title,
    this.titleTextStyle,
    this.image,
    this.imagePath,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final title = this.title ??
        FlutterI18n.translate(
          context,
          'ui.unknown',
        );

    return IrmaCard(
      color: backgroundColor,
      hasShadow: false,
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
            logoPath: imagePath,
            logoSemanticsLabel: title,
            initials: title != '' ? title[0] : null,
          ),
          SizedBox(
            width: theme.smallSpacing,
          ),
          Flexible(
            child: Text(
              title,
              style: titleTextStyle ??
                  theme.textTheme.bodyLarge!.copyWith(
                    color: textColor ?? theme.neutralExtraDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
