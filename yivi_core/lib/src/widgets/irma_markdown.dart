import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";

import "../providers/irma_repository_provider.dart";
import "../theme/theme.dart";

class IrmaMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;

  const IrmaMarkdown(this.data, {this.styleSheet});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      // Effectively disable image rendering (to prevent remote image loading)
      sizedImageBuilder: (config) => Container(),
      // Define small style sheet, and merge in any passed styleSheet
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
          .merge(
            MarkdownStyleSheet(
              h1: context.text.displayLarge,
              h2: context.text.displayMedium,
              h3: context.text.displaySmall,
              h4: context.text.headlineMedium,
              strong: context.text.bodyLarge,
              a: context.yivi.hyperlinkTextStyle,
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
