import "package:flutter/material.dart";

import "../theme/theme.dart";
import "irma_divider.dart";
import "loading_indicator.dart";
import "translated_text.dart";

class EndOfListIndicator extends StatelessWidget {
  final bool isLoading;

  const EndOfListIndicator({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final expandedDividerWidget = Expanded(
      child: IrmaDivider(color: context.colors.tertiary),
    );

    final statusIndicatorWidget = Padding(
      padding: EdgeInsets.symmetric(horizontal: context.yivi.spacing.base),
      child: Container(
        width: 24,
        height: 24,
        decoration: isLoading
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                color: context.yivi.brand.success,
              ),
        child: isLoading
            ? LoadingIndicator()
            : Icon(Icons.check, size: 18, color: Colors.white),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            expandedDividerWidget,
            statusIndicatorWidget,
            expandedDividerWidget,
          ],
        ),
        SizedBox(height: context.yivi.spacing.small),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.yivi.spacing.huge),
          child: TranslatedText(
            isLoading ? "ui.loading" : "ui.end_of_list",
            textAlign: TextAlign.center,
            style: context.yivi.indicator.endOfList,
          ),
        ),
      ],
    );
  }
}
