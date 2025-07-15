import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';

import '../theme/theme.dart';
import 'irma_card.dart';
import 'translated_text.dart';

class IrmaActionCard extends StatelessWidget {
  final String titleKey;
  final String? subtitleKey;
  final IconData icon;
  final Function()? onTap;
  final bool isFancy;

  const IrmaActionCard({
    super.key,
    required this.titleKey,
    required this.icon,
    this.subtitleKey,
    this.onTap,
    this.isFancy = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final isLandscape = MediaQuery.of(context).size.width > 450;

    final centeredLayout = subtitleKey == null || isLandscape;
    final contentColor = isFancy ? theme.light : theme.neutralExtraDark;

    Widget flexibleTitleTextWidget = Flexible(
      child: TranslatedText(
        titleKey,
        style: isFancy
            ? theme.textTheme.displayMedium!.copyWith(color: contentColor)
            : theme.textTheme.headlineMedium!.copyWith(color: theme.dark),
      ),
    );

    Widget? flexibleSubtitleTextWidget;
    if (subtitleKey != null) {
      flexibleSubtitleTextWidget = Flexible(
        child: TranslatedText(
          subtitleKey!,
          style: theme.textTheme.bodyMedium!.copyWith(fontSize: 14, color: contentColor, fontWeight: FontWeight.w600),
        ),
      );
    }

    final iconWidget = Icon(icon, size: isFancy ? 62 : 36, color: contentColor);

    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, titleKey),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: ExcludeSemantics(
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: isFancy
                    ? SvgPicture.asset('assets/ui/btn-bg.svg', alignment: Alignment.center, fit: BoxFit.fill)
                    : const IrmaCard(hasShadow: false),
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
                              iconWidget,
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
                                  SizedBox(width: theme.smallSpacing),
                                  iconWidget,
                                ],
                              ),
                              if (flexibleSubtitleTextWidget != null) ...[
                                SizedBox(height: theme.smallSpacing),
                                Row(children: [flexibleSubtitleTextWidget]),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
