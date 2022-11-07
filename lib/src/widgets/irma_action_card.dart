import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_card.dart';
import 'translated_text.dart';

class IrmaActionCard extends StatelessWidget {
  final String titleKey;
  final String? subtitleKey;
  final IconData icon;
  final TextStyle? style;
  final Color? color;
  final bool invertColors;
  final Function()? onTap;
  final bool centerText;

  const IrmaActionCard({
    Key? key,
    required this.titleKey,
    required this.icon,
    required this.color,
    this.subtitleKey,
    this.style,
    this.onTap,
    this.invertColors = false,
    this.centerText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final backgroundColor = invertColors ? Colors.white : color;
    final textColor = invertColors ? color : Colors.white;
    final textStyle = style ?? theme.textTheme.headline2 ?? const TextStyle();
    final captionStyle = theme.textTheme.caption ?? const TextStyle();

    return IrmaCard(
        color: backgroundColor,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.all(theme.defaultSpacing),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: TranslatedText(
                    titleKey,
                    style: textStyle.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: theme.largeSpacing,
                ),
                Icon(
                  icon,
                  size: (textStyle.fontSize ?? 24) * 2.5,
                  color: textColor,
                )
              ],
            ),
            if (subtitleKey != null) ...[
              SizedBox(
                height: theme.tinySpacing,
              ),
              TranslatedText(
                subtitleKey!,
                style: captionStyle.copyWith(color: textColor),
              )
            ]
          ],
        ));
  }
}
