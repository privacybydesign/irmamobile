import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/theme.dart';
import 'irma_repository_provider.dart';

class IrmaMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;

  const IrmaMarkdown(
    this.data, {
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return MarkdownBody(
      data: data,

      // Effectively disable image rendering (to prevent remote image loading)
      imageBuilder: (uri, title, alt) => Container(),

      // Define small style sheet, and merge in any passed styleSheet
      styleSheet: MarkdownStyleSheet.fromTheme(theme.themeData)
          .merge(MarkdownStyleSheet(
            strong: theme.textTheme.bodyText1,
            a: theme.hyperlinkTextStyle,
            textScaleFactor: MediaQuery.textScaleFactorOf(context),
          ))
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
