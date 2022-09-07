import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

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
    required this.titleKey,
    required this.icon,
    required this.color,
    this.subtitleKey,
    this.style,
    this.onTap,
    this.invertColors = false,
    this.centerText = false,
  });

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
      child: Row(
        crossAxisAlignment: centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  titleKey,
                  style: textStyle.copyWith(color: textColor),
                ),
                if (subtitleKey != null) ...[
                  SizedBox(height: theme.smallSpacing),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${FlutterI18n.translate(context, subtitleKey!)} ',
                          style: captionStyle.copyWith(color: textColor),
                        ),
                        WidgetSpan(
                          child: Icon(
                            Icons.arrow_forward,
                            size: textStyle.fontSize,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: theme.largeSpacing),
            child: Icon(
              icon,
              size: (textStyle.fontSize ?? 24) * 2.5,
              color: textColor,
            ),
          )
        ],
      ),
    );
  }
}
