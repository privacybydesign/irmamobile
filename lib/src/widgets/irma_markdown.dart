import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:irmamobile/src/screens/webview/webview_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';

class IrmaMarkdown extends StatelessWidget {
  final String data;

  const IrmaMarkdown({
    @required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      selectable: false,
      data: data,
      imageBuilder: (Uri uri) => Container(),
      styleSheet: MarkdownStyleSheet(
        strong: IrmaTheme.of(context).textTheme.body2,
        a: IrmaTheme.of(context).hyperlinkTextStyle,
        textScaleFactor: MediaQuery.textScaleFactorOf(
            context), // TODO remove that addition when "https://github.com/flutter/flutter_markdown/pull/162" is merged
      ),
      onTapLink: (href) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return WebviewScreen(href);
          }),
        );
      },
    );
  }
}
