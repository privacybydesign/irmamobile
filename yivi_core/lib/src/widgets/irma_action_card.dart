import "package:flutter/material.dart";

import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/svg.dart";

import "../../package_name.dart";
import "../theme/theme.dart";
import "irma_card.dart";
import "translated_text.dart";

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
    final isLandscape = MediaQuery.of(context).size.width > 450;

    final centeredLayout = subtitleKey == null || isLandscape;
    final contentColor = isFancy
        ? Colors.white
        : context.colors.onSurfaceVariant;

    Widget flexibleTitleTextWidget = Flexible(
      child: TranslatedText(
        titleKey,
        style: isFancy
            ? context.text.headlineMedium!.copyWith(color: contentColor)
            : context.text.titleMedium!.copyWith(
                color: context.colors.onSurface,
              ),
      ),
    );

    Widget? flexibleSubtitleTextWidget;
    if (subtitleKey != null) {
      flexibleSubtitleTextWidget = Flexible(
        child: TranslatedText(
          subtitleKey!,
          style: context.text.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: contentColor,
          ),
        ),
      );
    }

    final iconWidget = Icon(icon, size: isFancy ? 62 : 36, color: contentColor);

    return Semantics(
      button: true,
      label: FlutterI18n.translate(context, titleKey),
      child: Container(
        decoration: isFancy
            ? null
            : BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    offset: const Offset(0.0, 1.0),
                    blurRadius: 6.0,
                  ),
                ],
              ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: ExcludeSemantics(
            child: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: isFancy
                      ? SvgPicture.asset(
                          yiviAsset("ui/btn-bg.svg"),
                          alignment: Alignment.center,
                          fit: BoxFit.fill,
                        )
                      : const IrmaCard(hasShadow: false),
                ),

                // Content
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: EdgeInsets.all(context.yivi.defaultSpacing),
                      child: centeredLayout
                          // Layout where the text is centrally aligned with the icon
                          ? Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      flexibleTitleTextWidget,
                                      if (flexibleSubtitleTextWidget != null)
                                        flexibleSubtitleTextWidget,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    flexibleTitleTextWidget,
                                    SizedBox(width: context.yivi.smallSpacing),
                                    iconWidget,
                                  ],
                                ),
                                if (flexibleSubtitleTextWidget != null) ...[
                                  SizedBox(height: context.yivi.smallSpacing),
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
      ),
    );
  }
}
