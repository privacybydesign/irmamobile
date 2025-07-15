import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme/theme.dart';
import 'irma_card.dart';

class IrmaQuote extends StatelessWidget {
  final String? quote;
  final RichText? richQuote;
  final Color? color;

  const IrmaQuote({super.key, this.quote, this.richQuote, this.color})
    : assert(quote != null || richQuote != null, 'No quote given. Set quote or richQuote.'),
      assert(quote == null || richQuote == null, 'Either set quote or richQuote, not both.');

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      padding: EdgeInsets.zero,
      hasShadow: false,
      style: IrmaCardStyle.highlighted,
      child: Row(
        children: [
          Flexible(
            child: quote != null
                ? MarkdownBody(
                    data: FlutterI18n.translate(context, quote!),
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      ThemeData(
                        textTheme: TextTheme(
                          bodyMedium: theme.textTheme.bodyMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
                        ),
                      ),
                    ),
                  )
                : richQuote!,
          ),
        ],
      ),
    );
  }
}
