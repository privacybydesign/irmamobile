import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_markdown/flutter_markdown.dart";

import "../theme/theme.dart";
import "irma_card.dart";

class IrmaQuote extends StatelessWidget {
  final String? quote;
  final RichText? richQuote;

  /// An arbitrary widget to render inside the quote card. Mutually exclusive
  /// with [quote] and [richQuote]; use it when the content needs its own layout
  /// (for example a message with an inline "Read more" affordance).
  final Widget? child;
  final Color? color;

  const IrmaQuote({
    super.key,
    this.quote,
    this.richQuote,
    this.child,
    this.color,
  }) : assert(
         quote != null || richQuote != null || child != null,
         "No content given. Set quote, richQuote or child.",
       ),
       assert(
         (quote != null ? 1 : 0) +
                 (richQuote != null ? 1 : 0) +
                 (child != null ? 1 : 0) ==
             1,
         "Set exactly one of quote, richQuote or child.",
       );

  @override
  Widget build(BuildContext context) {
    return IrmaCard(
      padding: EdgeInsets.zero,
      hasShadow: false,
      style: IrmaCardStyle.highlighted,
      child: Row(
        children: [
          Flexible(
            child: child != null
                ? child!
                : quote != null
                ? MarkdownBody(
                    data: FlutterI18n.translate(context, quote!),
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      ThemeData(
                        textTheme: TextTheme(
                          bodyMedium: context.yivi.card.quoteBody,
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
