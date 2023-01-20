import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/theme.dart';
import 'translated_text.dart';

class IrmaActionCard extends StatelessWidget {
  final String titleKey;
  final String? subtitleKey;
  final IconData icon;

  final Color? color;
  final Function()? onTap;

  const IrmaActionCard({
    Key? key,
    required this.titleKey,
    required this.icon,
    this.color,
    this.subtitleKey,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).size.width > 450;

    final centeredLayout = subtitleKey == null || isLandscape;
    final contentColor = color ?? theme.light;

    Widget flexibleTitleTextWidget = Flexible(
      child: TranslatedText(
        titleKey,
        style: theme.textTheme.headline2!.copyWith(
          color: contentColor,
        ),
      ),
    );

    Widget? flexibleSubtitleTextWidget;
    if (subtitleKey != null) {
      flexibleSubtitleTextWidget = Flexible(
        child: TranslatedText(
          subtitleKey!,
          style: theme.textTheme.bodyText2!.copyWith(fontSize: 14, color: contentColor, fontWeight: FontWeight.w600),
        ),
      );
    }

    final iconWidget = Icon(
      icon,
      size: 62,
      color: contentColor,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(8),
      ),
      child: Stack(
        children: [
          // Background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/ui/btn-bg.svg',
              alignment: Alignment.center,
              fit: BoxFit.fill,
            ),
          ),

          // Content
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(theme.defaultSpacing),
                child: centeredLayout
                    // Layout where the text is centrally aligned with the icon
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                flexibleTitleTextWidget,
                                if (flexibleSubtitleTextWidget != null) flexibleSubtitleTextWidget,
                              ],
                            ),
                          ),
                          iconWidget
                        ],
                      )
                    // Layout where the text and the icon stick to the top
                    // and the subtitle can extend underneath the icon
                    : Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              flexibleTitleTextWidget,
                              SizedBox(
                                width: theme.smallSpacing,
                              ),
                              iconWidget
                            ],
                          ),
                          if (flexibleSubtitleTextWidget != null) ...[
                            SizedBox(
                              height: theme.smallSpacing,
                            ),
                            Row(
                              children: [
                                flexibleSubtitleTextWidget,
                              ],
                            )
                          ]
                        ],
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
