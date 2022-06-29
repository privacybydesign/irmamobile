import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../theme/theme.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/translated_text.dart';

class IrmaActionCard extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final bool invertColors;
  final Function()? onTap;

  const IrmaActionCard({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    this.onTap,
    this.invertColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final backgroundColor = invertColors ? Colors.white : theme.themeData.colorScheme.primary;
    final textColor = invertColors ? theme.themeData.colorScheme.primary : Colors.white;

    return IrmaCard(
      color: backgroundColor,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.all(theme.defaultSpacing),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  titleKey,
                  style: theme.textTheme.headline2!.copyWith(color: textColor),
                ),
                SizedBox(height: theme.smallSpacing),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${FlutterI18n.translate(context, subtitleKey)} ',
                        style: theme.textTheme.caption!.copyWith(color: textColor),
                      ),
                      WidgetSpan(
                        child: Icon(
                          Icons.arrow_forward,
                          size: 22,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: theme.largeSpacing),
            child: Icon(
              icon,
              size: 62,
              color: textColor,
            ),
          )
        ],
      ),
    );
  }
}
