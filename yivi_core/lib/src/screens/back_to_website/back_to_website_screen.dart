import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/adaptive_layout.dart";
import "../../util/i18n.dart";
import "../../widgets/buttons/pill_buttons.dart";
import "../../widgets/surfaces/numbered_step.dart";
import "../../widgets/surfaces/surface_card.dart";
import "../../widgets/text/translated_text.dart";
import "../enrollment/widgets/enrollment_page.dart";

/// From the empty Data tab ("On a website on this phone?"): how to go back
/// to the website that asked for Yivi, so it opens the app with its request.
/// Yivi can't tell which website it was, so the page never names one.
class BackToWebsiteScreen extends StatelessWidget {
  const BackToWebsiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final sideways = enrollmentSideways(context);
    final tablet = isTabletWindow(context);
    final align = sideways ? TextAlign.start : TextAlign.center;

    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnrollmentTitle("back_to_website.title", textAlign: align),
        const SizedBox(height: YiviSpace.x16),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: YiviSpace.x16,
            vertical: YiviSpace.x4,
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: YiviSpace.x12),
                child: NumberedStep(
                  number: 1,
                  child: TranslatedText("back_to_website.step_1"),
                ),
              ),
              Divider(height: 1, color: palette.divider),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: YiviSpace.x12),
                child: NumberedStep(
                  number: 2,
                  child: TranslatedText("back_to_website.step_2"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: YiviSpace.x12),
        TranslatedText(
          "back_to_website.hint",
          textAlign: align,
          style: palette
              .body(tablet ? 15 : 14)
              .copyWith(color: palette.secondaryText),
        ),
      ],
    );

    return EnrollmentPage(
      about: const Center(child: _BrowserSketch()),
      action: action,
      trailing: YiviIconButton(
        key: const Key("back_to_website_close"),
        label: context.tr("accessibility.close"),
        icon: CupertinoIcons.xmark,
        onTap: () => Navigator.of(context).pop(),
        look: IconButtonLook.bar,
      ),
    );
  }
}

/// A browser on the phone with the website's "Open Yivi app" button.
/// Purely illustrative: the steps say the same.
class _BrowserSketch extends StatelessWidget {
  const _BrowserSketch();

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final scale = isTabletWindow(context) ? 1.3 : 1.0;
    Widget bar(double width, double height, Color color) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: 220 * scale,
        height: 226 * scale,
        child: FittedBox(
          child: SurfaceCard(
            width: 220,
            height: 226,
            padding: const EdgeInsets.all(YiviSpace.x12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: palette.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                bar(96, 9, palette.divider),
                const SizedBox(height: YiviSpace.x8),
                bar(140, 6, palette.divider),
                const SizedBox(height: 5),
                bar(110, 6, palette.divider),
                const Spacer(),
                Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.35),
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: TranslatedText(
                    "back_to_website.sketch_button",
                    style: palette
                        .body(13, weight: FontWeight.w700)
                        .copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: YiviSpace.x8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
