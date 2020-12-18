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
      imageBuilder: (Uri uri) => Container(),

      // Define small stylesheet, and merge in any passed styleSheet
      styleSheet: MarkdownStyleSheet(
        strong: IrmaTheme.of(context).textTheme.body2,
        a: IrmaTheme.of(context).hyperlinkTextStyle,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
      ).merge(styleSheet),

      // View links in in-app browser
      onTapLink: (href) {
        IrmaRepository.get().openURL(context, href);
      },
    );
  }
}
