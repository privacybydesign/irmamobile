import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/theme.dart';

class IrmaQuote extends StatelessWidget {
  final String? quote;
  final RichText? richQuote;
  final Color? color;
  final BoxDecoration? boxDecoration;

  const IrmaQuote({
    this.quote,
    this.richQuote,
    this.color,
    this.boxDecoration,
  })  : assert(
          quote != null || richQuote != null,
          'No quote given. Set quote or richQuote.',
        ),
        assert(
          quote == null || richQuote == null,
          'Either set quote or richQuote, not both.',
        );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Container(
      decoration: boxDecoration,
      color: (boxDecoration != null) ? null : color ?? theme.surfaceSecondary,
      child: Padding(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Row(
          children: [
            Flexible(
              child: quote != null
                  ? MarkdownBody(
                      data: FlutterI18n.translate(context, quote!),
                      styleSheet: MarkdownStyleSheet.fromTheme(
                        ThemeData(
                          textTheme: TextTheme(
                            //Set the default markdown text to the caption style in our theme.
                            bodyText2: theme.textTheme.caption,
                          ),
                        ),
                      ))
                  : richQuote!,
            )
          ],
        ),
      ),
    );
  }
}
