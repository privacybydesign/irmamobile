import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/translated_text.dart";
import "../../../widgets/yivi_themed_button.dart";
import "dynamic_layout.dart";
import "session_columns.dart";
import "session_scaffold.dart";

class DisclosurePermissionIntroductionScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const DisclosurePermissionIntroductionScreen({
    super.key,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // Tablets: the picture on a disc on the left, the text and the button
    // on the right.
    if (useSessionColumns(context)) {
      final palette = YiviPalette.of(context);
      return SessionScaffold(
        appBarTitle: "disclosure_permission.introduction.title",
        onDismiss: onDismiss,
        wide: true,
        scrollsUnderBars: true,
        body: SessionColumns(
          startWidth: 400,
          endWidth: 400,
          gap: 96,
          centreVertically: true,
          start: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: SvgPicture.asset(
                  yiviAsset("disclosure/disclosure_intro.svg"),
                ),
              ),
            ),
          ),
          end: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                "disclosure_permission.introduction.header",
                isHeader: true,
                style: palette
                    .display(34, weight: FontWeight.w700)
                    .copyWith(height: 44 / 34, color: palette.heading),
              ),
              const SizedBox(height: 12),
              TranslatedText(
                "disclosure_permission.introduction.explanation",
                style: palette.body(18).copyWith(height: 28 / 18),
              ),
            ],
          ),
          actions: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: YiviThemedButton(
              label: "disclosure_permission.introduction.continue",
              onPressed: onContinue,
            ),
          ),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "disclosure_permission.introduction.title",
      onDismiss: onDismiss,
      body: DynamicLayout(
        hero: SvgPicture.asset(yiviAsset("disclosure/disclosure_intro.svg")),
        content: Column(
          children: [
            TranslatedText(
              "disclosure_permission.introduction.header",
              style: theme.themeData.textTheme.displaySmall!.copyWith(
                color: theme.dark,
              ),
            ),
            SizedBox(height: theme.tinySpacing),
            TranslatedText(
              "disclosure_permission.introduction.explanation",
              style: theme.themeData.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          YiviThemedButton(
            label: "disclosure_permission.introduction.continue",
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
