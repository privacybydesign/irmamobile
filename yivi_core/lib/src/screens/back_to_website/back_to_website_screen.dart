import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/surface_card.dart";
import "../../widgets/translated_text.dart";
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
    final tablet = enrollmentTablet(context);
    final align = sideways ? TextAlign.start : TextAlign.center;

    final action = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnrollmentTitle("back_to_website.title", textAlign: align),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              const _Step(number: 1, textKey: "back_to_website.step_1"),
              Divider(height: 1, color: palette.divider),
              const _Step(number: 2, textKey: "back_to_website.step_2"),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
      trailing: GlassIconButton(
        key: const Key("back_to_website_close"),
        semanticsLabel: FlutterI18n.translate(context, "accessibility.close"),
        icon: Icon(Icons.close_rounded, size: 22, color: palette.text),
        onTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String textKey;

  const _Step({required this.number, required this.textKey});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.tint,
                shape: BoxShape.circle,
              ),
              child: Text(
                "$number",
                style: palette
                    .display(13, weight: FontWeight.w700)
                    .copyWith(color: palette.link),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: TranslatedText(
                textKey,
                style: palette.body(15).copyWith(height: 21 / 15),
              ),
            ),
          ),
        ],
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
    final scale = enrollmentTablet(context) ? 1.3 : 1.0;
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
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
