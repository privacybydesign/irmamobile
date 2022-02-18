// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaMarkdown extends StatelessWidget {
  final String _data;
  final MarkdownStyleSheet styleSheet;

  const IrmaMarkdown(
    this._data, {
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _data,

      // if selectable is true, links in the markdown do not seem to work
      selectable: false,

      // Effectively disable image rendering (to prevent remote image loading)
      imageBuilder: (uri, title, alt) => Container(),

      // Define small stylesheet, and merge in any passed styleSheet
      styleSheet: MarkdownStyleSheet.fromTheme(IrmaTheme.of(context).themeData)
          .merge(MarkdownStyleSheet(
            strong: IrmaTheme.of(context).textTheme.bodyText1,
            a: IrmaTheme.of(context).hyperlinkTextStyle,
            textScaleFactor: MediaQuery.textScaleFactorOf(context),
          ))
          .merge(styleSheet),

      // View links in in-app browser
      onTapLink: (text, href, alt) {
        IrmaRepository.get().openURL(href);
      },
    );
  }
}
