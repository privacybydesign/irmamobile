import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../widgets/feedback/spinner.dart";
import "../../../widgets/text/translated_text.dart";

/// Under a list while more of it loads: a spinner between two lines, and
/// "Loading…". A list that has come to its end shows nothing: it just ends.
class LoadingMoreIndicator extends StatelessWidget {
  const LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = YiviTheme.of(context);

    final expandedDividerWidget = Expanded(
      child: Container(height: 1, color: YiviPalette.of(context).outline),
    );

    return Column(
      children: [
        Row(
          children: [
            expandedDividerWidget,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x16),
              child: Spinner(size: 24),
            ),
            expandedDividerWidget,
          ],
        ),
        const SizedBox(height: YiviSpace.x8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: YiviSpace.x64),
          child: TranslatedText(
            "ui.loading",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: YiviPalette.of(context).heading,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}
