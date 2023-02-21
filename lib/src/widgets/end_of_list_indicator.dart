import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'irma_divider.dart';
import 'loading_indicator.dart';
import 'translated_text.dart';

class EndOfListIndicator extends StatelessWidget {
  final bool isLoading;

  const EndOfListIndicator({
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final expandedDividerWidget = Expanded(
      child: IrmaDivider(
        color: theme.tertiary,
      ),
    );

    final statusIndicatorWidget = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.defaultSpacing,
      ),
      child: Container(
        width: 24,
        height: 24,
        decoration: isLoading
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                color: theme.success,
              ),
        child: isLoading
            ? LoadingIndicator()
            : Icon(
                Icons.check,
                size: 18,
                color: theme.light,
              ),
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
        SizedBox(
          height: theme.smallSpacing,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.hugeSpacing),
          child: TranslatedText(
            isLoading ? 'ui.loading' : 'ui.end_of_list',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyText2!.copyWith(
              color: theme.neutralExtraDark,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        )
      ],
    );
  }
}
