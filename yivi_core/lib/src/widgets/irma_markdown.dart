import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/irma_repository_provider.dart';
import '../theme/theme.dart';

class IrmaMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;

  const IrmaMarkdown(this.data, {this.styleSheet});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return MarkdownBody(
      data: data,
      // Effectively disable image rendering (to prevent remote image loading)
      sizedImageBuilder: (config) => Container(),
      // Define small style sheet, and merge in any passed styleSheet
      styleSheet: MarkdownStyleSheet.fromTheme(theme.themeData)
          .merge(
            MarkdownStyleSheet(
              h1: theme.textTheme.displayLarge,
              h2: theme.textTheme.displayMedium,
              h3: theme.textTheme.displaySmall,
              h4: theme.textTheme.headlineMedium,
              strong: theme.textTheme.bodyLarge,
              a: theme.hyperlinkTextStyle,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          )
          .merge(styleSheet),

      // View links in in-app browser
      onTapLink: (text, href, alt) {
        if (href != null) {
          IrmaRepositoryProvider.of(context).openURL(href);
        }
      },
    );
  }
}
