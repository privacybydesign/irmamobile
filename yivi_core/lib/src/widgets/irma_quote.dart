// flutter_markdown_plus still takes the core SDK's ThemeData, so build that one
// here.
import "package:flutter/material.dart" as core;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:material_ui/material_ui.dart";

import "../theme/theme.dart";
import "irma_card.dart";

class IrmaQuote extends StatelessWidget {
  final String? quote;

  /// An arbitrary widget to render inside the quote card. Mutually exclusive
  /// with [quote]; use it when the content needs its own layout (for example
  /// a message with an inline "Read more" affordance).
  final Widget? child;
  final Color? color;

  const IrmaQuote({super.key, this.quote, this.child, this.color})
    : assert(
        (quote == null) != (child == null),
        "Set exactly one of quote or child.",
      );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IrmaCard(
      padding: EdgeInsets.zero,
      style: IrmaCardStyle.highlighted,
      child: Row(
        children: [
          Flexible(
            child:
                child ??
                MarkdownBody(
                  data: FlutterI18n.translate(context, quote!),
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    core.ThemeData(
                      textTheme: core.TextTheme(
                        bodyMedium: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
