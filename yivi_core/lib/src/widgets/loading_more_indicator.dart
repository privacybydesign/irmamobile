import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "irma_divider.dart";
import "loading_indicator.dart";
import "translated_text.dart";

/// Under a list while more of it loads: a spinner between two lines, and
/// "Loading…". A list that has come to its end shows nothing: it just ends.
class LoadingMoreIndicator extends StatelessWidget {
  const LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final expandedDividerWidget = Expanded(
      child: IrmaDivider(color: theme.tertiary),
    );

    return Column(
      children: [
        Row(
          children: [
            expandedDividerWidget,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
              child: SizedBox(width: 24, height: 24, child: LoadingIndicator()),
            ),
            expandedDividerWidget,
          ],
        ),
        SizedBox(height: theme.smallSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.hugeSpacing),
          child: TranslatedText(
            "ui.loading",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.neutralExtraDark,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}
