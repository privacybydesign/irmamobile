// flutter_markdown_plus still takes the core SDK's ThemeData, so read that one
// here.
import "package:flutter/material.dart" as core;
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:material_ui/material_ui.dart";

import "../providers/irma_repository_provider.dart";
import "../theme/theme.dart";

/// The link schemes [IrmaMarkdown] opens. Markdown can come from issuers, for
/// example the FAQ in EUDI credential metadata, and openURL hands any scheme to
/// the platform: a link could otherwise launch another app through its custom
/// scheme, or open a javascript: or file: URL. Links to other schemes are ignored.
const allowedMarkdownLinkSchemes = {"https", "mailto"};

/// Whether [IrmaMarkdown] opens [href].
bool isAllowedMarkdownLink(String href) {
  final uri = Uri.tryParse(href.trim());
  return uri != null &&
      allowedMarkdownLinkSchemes.contains(uri.scheme.toLowerCase()) &&
      (uri.scheme.toLowerCase() != "https" || uri.host.isNotEmpty);
}

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
      imageBuilder: (uri, title, alt) => Container(),
      // Define small style sheet, and merge in any passed styleSheet
      styleSheet: MarkdownStyleSheet.fromTheme(core.Theme.of(context))
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

      // View https links in the in-app browser, open mailto links in the mail
      // app, and ignore any other link (see allowedMarkdownLinkSchemes).
      onTapLink: (text, href, alt) {
        if (href != null && isAllowedMarkdownLink(href)) {
          IrmaRepositoryProvider.of(context).openURL(href.trim());
        }
      },
    );
  }
}
